import Config

port = 4000

config :calc, CalcWeb.Endpoint,
  http: [:inet6, port: port],
  url: [host: "localhost", port: port],
  render_errors: [view: CalcWeb.ErrorView, accepts: ~w(json), layout: false]

config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :phoenix, :json_library, Jason

import_config "#{Mix.env()}.exs"
