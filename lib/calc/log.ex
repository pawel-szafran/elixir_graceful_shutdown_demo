defmodule Calc.Log do
  use Supervisor
  require Logger

  def start_link(args) do
    Supervisor.start_link(__MODULE__, args, name: __MODULE__)
  end

  @impl true
  def init(_args) do
    children = [
      {Finch, name: __MODULE__.Finch},
      __MODULE__.Server
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  def publish_async(op, numbers, result) do
    __MODULE__.Server.publish(op, numbers, result)
  end
end
