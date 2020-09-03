ARG ELIXIR_VERSION=1.10.4
ARG OTP_VERSION=23.0.3
ARG ALPINE_VERSION=3.12.0

#----------------------------------------------------------------
# Build
#----------------------------------------------------------------

FROM hexpm/elixir:${ELIXIR_VERSION}-erlang-${OTP_VERSION}-alpine-${ALPINE_VERSION} as build

ARG ELIXIR_VERSION
ARG OTP_VERSION
ARG ALPINE_VERSION

RUN mix do local.hex --force, local.rebar --force

WORKDIR /build

# Get deps
COPY mix.* ./
RUN mix deps.get

ENV MIX_ENV prod

# Copy configs and compile deps for all envs
COPY config config
RUN mix deps.compile

# Copy sources
COPY lib lib
COPY .formatter.exs .formatter.exs

# Build release
RUN mix release

#----------------------------------------------------------------
# Run
#----------------------------------------------------------------

FROM alpine:${ALPINE_VERSION} as run

RUN apk add --update --no-cache bash openssl

WORKDIR /app

COPY --from=build /build/_build/prod/rel/calc ./

RUN addgroup -S app && adduser -S app -G app
RUN chown -R app:app /app
USER app

EXPOSE 4000

CMD ["/app/bin/calc", "start"]
