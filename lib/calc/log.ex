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
      {Task.Supervisor, name: __MODULE__.Task.Supervisor}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  def publish_async(op, numbers, result) do
    Logger.info("Logging operation... ")
    numbers = length(numbers)

    Task.Supervisor.start_child(
      __MODULE__.Task.Supervisor,
      fn ->
        Process.flag(:trap_exit, true)
        publish(op, numbers, result)
      end,
      shutdown: 7_000
    )
  end

  defp publish(op, numbers, result) do
    Process.sleep(5_000)
    write_to_influxdb("operation,name=#{op} numbers=#{numbers},result=#{result}")
  end

  defp write_to_influxdb(log) do
    Finch.build(:post, influxdb_url("/write?db=calc"), [], log)
    |> Finch.request(__MODULE__.Finch)
    |> parse_response()
  end

  defp influxdb_url(path), do: influxdb_base_url() <> path

  defp influxdb_base_url do
    Application.fetch_env!(:calc, Calc.Log)
    |> Keyword.fetch!(:influxdb_base_url)
  end

  defp parse_response({:ok, _}) do
    Logger.info("Operation logged")
    :ok
  end

  defp parse_response({:error, reason} = error) do
    Logger.info("Couldn't log operation: #{inspect(reason)}")
    error
  end
end
