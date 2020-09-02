# TARGETS

.PHONY: help \
	set-calc-url \
	local-server local-test \
	do-create-registry do-create-k8s-cluster do-add-registry-to-k8s-cluster \
	do-create-load-test-vm do-load-test do-create-cert do-delete \
	docker-local-server docker-push-image \
	k8s-logs k8s-apply-deployment k8s-deploy k8s-redeploy k8s-test k8s-delete

help:
	@grep -E '^[a-zA-Z1-9_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

set-calc-url: ## Set calc url for k8s-test and do-load-test
	$(if $(url), , $(error "Specify url, e.g.: url=https://calc.pawelszafran.online"))
	echo $(url) > .make.calc-url

# Local

.make.local-tools: .tool-versions
	asdf install
	touch .make.local-tools

.make.local-deps-get: mix.exs
	mix deps.get
	touch .make.local-deps-get

local-server: .make.local-tools .make.local-deps-get  ## Local: Run server
	exec iex -S mix phx.server

local-test: ## Local: Test server
	curl -X POST http://localhost:4000/sum \
		-H 'Content-Type: application/json' \
		-d '{"numbers": [1, 2, 3, 4]}'  	

# DigitalOcean (DO)

.make.do-registry:
	$(if $(name), , $(error "Specify unique registry name, e.g.: name=my-registry"))
	doctl registry create $(name)
	doctl registry login
	echo $(name) > .make.do-registry

do-create-registry: .make.do-registry  ## DigitalOcean: Create registry

.make.do-k8s-cluster:
	doctl kubernetes cluster create graceful-shutdown-demo \
		--region fra1 \
		--node-pool "name=k8s;size=s-2vcpu-2gb;count=3"
	touch .make.do-k8s-cluster

do-create-k8s-cluster: .make.do-k8s-cluster  ## DigitalOcean: Create k8s cluster

do-add-registry-to-k8s-cluster: .make.do-registry .make.do-k8s-cluster ## DigitalOcean: Add registry to k8s cluster
	doctl registry kubernetes-manifest | kubectl apply -f -
	kubectl patch serviceaccount default \
		-p '{"imagePullSecrets": [{"name": "registry-$(file < .make.do-registry)"}]}'

do-create-cert: ## DigitalOcean: Create TLS certificate for HTTPS and HTTP/2
	$(if $(domain), , $(error "Specify domain, e.g.: domain=calc.pawelszafran.online"))
	doctl compute certificate create \
		--type lets_encrypt \
		--name calc \
		--dns-names $(domain)

.make.do-ssh-key:
	doctl compute ssh-key import local \
  	--public-key-file ~/.ssh/id_rsa.pub -o json \
  	| jq '.[0].id' \
		> .make.do-ssh-key

.make.do-load-test-vm: .make.do-ssh-key
	doctl compute droplet create graceful-shutdown-test \
		--image ubuntu-20-04-x64 \
		--region fra1 \
		--size s-4vcpu-8gb \
		--ssh-keys $(file < .make.do-ssh-key) \
		--wait \
		-o json \
		| jq '.[0].networks.v4[0].ip_address' -r \
		> .make.do-load-test-vm

.make.do-load-test-vm-setup: .make.do-load-test-vm
	@while !(ssh root@$(file < .make.do-load-test-vm) 'uname -a'); do sleep 2 ; done
	ssh root@$(file < .make.do-load-test-vm) < k6/ubuntu-install.sh
	touch .make.do-load-test-vm-setup

do-create-load-test-vm: .make.do-load-test-vm-setup ## DigitalOcean: Create load test VM

do-load-test: .make.do-load-test-vm-setup ## DigitalOcean: Run k6 load test from different DC
	scp k6/load-test.js root@$(file < .make.do-load-test-vm):
	ssh -t root@$(file < .make.do-load-test-vm) \
		'k6 run -e CALC_URL="$(file < .make.calc-url)" load-test.js'

do-delete: ## DigitalOcean: Delete all resources
	-doctl compute droplet delete graceful-shutdown-test -f
	-doctl kubernetes cluster delete graceful-shutdown-demo -f
	-doctl registry delete pawel-szafran -f
	-doctl compute ssh-key delete $(file < .make.do-ssh-key) -f
	rm -rf .make.do-*

# Docker

docker-local-server: ## Docker: Run local 
	docker build -t calc .
	docker run -it --rm --name calc -p 4000:4000 calc

docker-push-image: .make.do-registry ## Docker: Build and push image to registry
	$(if $(v), , $(error "Specify version, e.g.: v=0.1.0"))
	docker build -t registry.digitalocean.com/$(file < .make.do-registry)/calc:$(v) .
	docker push registry.digitalocean.com/$(file < .make.do-registry)/calc:$(v)

# k8s

k8s-logs: ## k8s: Print logs
	stern calc --since 1s

k8s-apply-deployment: .make.do-k8s-cluster
	$(if $(v), , $(error "Specify version, e.g.: v=0.1.0"))
	sed 's/CALC_VERSION/$(v)/g' k8s/deployment.yml | kubectl apply -f -
	kubectl rollout status deployment/calc

.make.k8s-service: .make.do-k8s-cluster
	kubectl apply -f k8s/service.yml
	@echo -n Waiting for Load Balancer external IP... ''
	@while !(kubectl get services/calc -o jsonpath="{.status.loadBalancer.ingress[*].ip}" | grep .); do sleep 2 ; done
	kubectl get services/calc -o jsonpath="{.status.loadBalancer.ingress[*].ip}" | awk '$$0="http://"$$0' > .make.calc-url
	touch .make.k8s-service

k8s-deploy: k8s-apply-deployment .make.k8s-service ## k8s: Deploy

k8s-redeploy:
	kubectl rollout restart deployment/calc
	kubectl rollout status deployment/calc

k8s-test: .make.calc-url ## k8s: Test service
	curl -X POST $(file < .make.calc-url)/sum \
		-H 'Content-Type: application/json' \
		-d '{"numbers": [1, 2, 3, 4]}'  	

k8s-delete: ## k8s: Delete resources
	-kubectl delete service/calc
	-kubectl delete deployment/calc
	rm -f .make.k8s-*
