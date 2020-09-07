defmodule Calc.Application do
  use Application
  require Logger

  def start(_type, _args) do
    Logger.info("App starting...")

    children = [
      Calc.Log,
      CalcWeb.Telemetry,
      CalcWeb.Endpoint
    ]

    opts = [strategy: :one_for_one, name: Calc.Supervisor]
    supervisor = Supervisor.start_link(children, opts)
    Logger.info("App started")
    supervisor
  end

  def prep_stop(_state) do
    Logger.info("App stopping...")
  end

  def stop(_state) do
    Logger.info("App stopped")
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    CalcWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
