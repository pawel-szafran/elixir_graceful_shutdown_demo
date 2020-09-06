defmodule Calc.Application do
  use Application

  def start(_type, _args) do
    children = [
      {Finch, name: CalcFinch},
      CalcWeb.Telemetry,
      CalcWeb.Endpoint
    ]

    opts = [strategy: :one_for_one, name: Calc.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    CalcWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
