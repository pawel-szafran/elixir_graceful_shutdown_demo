# Graceful Shutdown in Elixir DEMO

Demo app for my [Code BEAM
V](https://codesync.global/conferences/code-beam-sto/) talk "Graceful shutdown
in Elixir - try not to drop the ball".

## Versions

### `v1` - simple calc API

Dead simple calc API with a single `sum` endpoint, which slowly adds the numbers
(100ms sleep). Deployed to k8s with very min config.

Problems:
- Failures when deploying
- Failures when scaling up

## How to

### Play locally

Run local server (IEx):
```
make local-server
```

Test local-server:
```
make local-test
```

Run local server in Docker:
```
make docker-local-server
```

### Deploy to k8s

Create [DigitalOcean (DO)](https://www.digitalocean.com) account.

Install [`doctl`](https://github.com/digitalocean/doctl) and authenticate with
your DO account:
```
doctl auth init
```

Create DO Docker container repository, e.g.:
```
make do-create-registry name=pawel-szafran
```

Create k8s cluster with 3 nodes in Frankfurt:
```
make do-create-k8s-cluster
```

Add Docker registry to created k8s cluster:
```
make do-add-registry-to-k8s-cluster
```

Build and push Docker image to registry:
```
make docker-push-image v=0.1.0
```

Deploy app to k8s:
```
make k8s-deploy v=0.1.0
```

This will create a deployment with 13 app replicas:
```
$ kubectl get deployment/calc
NAME   READY   UP-TO-DATE   AVAILABLE   AGE
calc   13/13   13           13          5m31s
```

And will create a service with DO Load Balancer (may take few minutes):
```
$ kubectl get services/calc
NAME   TYPE           CLUSTER-IP    EXTERNAL-IP      PORT(S)        AGE
calc   LoadBalancer   10.245.0.14   157.230.76.110   80:30886/TCP   3m57s
```

Test k8s service:
```
make k8s-test
```

Watch app logs:
```
make k8s-logs
```

### Load test k8s deployment

Create load test VM and install load testing tool [`k6`](https://k6.io/docs/):
```
make do-create-load-test-vm
```

Load test the app with 500 virtual users for 5m (press `ctrl+c` to finish test
earlier):
```
make do-load-test
```

### Test with HTTPS and HTTP/2

Add your domain e.g. `pawelszafran.online` [to your DO
account](https://www.digitalocean.com/docs/networking/dns/how-to/add-domains/).

Create TLS certificate for `calc` subdomain:
```
make do-create-cert domain=calc.pawelszafran.online
```

[Create DNS
record](https://www.digitalocean.com/docs/networking/dns/how-to/manage-records/)
`A` for `calc` subdomain directing to the external IP of DO Load Balancer with
TTL of e.g. 10m.

[Update DO Load
Balancer's](https://www.digitalocean.com/docs/networking/load-balancers/how-to/manage/)
forwarding rules:
```
Old:
  TCP 80 -> TCP 30475

HTTPS:
  HTTP 80 -> HTTP 30475
  HTTPS 443 (cert: calc) -> HTTP 30475

or HTTP/2:
  HTTP 80 -> HTTP 30475
  HTTP2 443 (cert: calc) -> HTTP 30475
```

Set new URL for tests:

```
make set-calc-url url=https://calc.pawelszafran.online
```

### Test how deploying and scaling affects user traffic

Run load test, and while it's running, bump the number or replicas up or down:
```
kubectl scale deployment/calc --replicas=5
```

Or redeploy (restart last rollout):
```
make k8s-redeploy
```

Or push the same code 2x with 2 different versions, e.g. for Git tag `v1`:
```
make docker-push-image v=0.1.0
make docker-push-image v=0.1.1

make k8s-deploy v=0.1.0
make k8s-deploy v=0.1.1
```

### Clean up

```
make k8s-delete
make do-delete
```
