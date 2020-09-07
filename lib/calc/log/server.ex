defmodule Calc.Log.Server do
  use GenServer
  require Logger

  @publish_size 500
  @publish_interval 30_000

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def publish(op, numbers, result) do
    timestamp = DateTime.utc_now() |> DateTime.to_unix(:nanosecond)
    request_id = Logger.metadata()[:request_id]
    numbers = length(numbers)
    log = "operation,name=#{op},id=#{request_id} numbers=#{numbers},result=#{result} #{timestamp}"
    GenServer.cast(__MODULE__, {:publish, log})
  end

  @impl true
  def init(:ok) do
    {:ok, %{logs: {0, []}, timer: schedule_publishing()}}
  end

  @impl true
  def handle_cast({:publish, log}, %{logs: {size, logs}} = state)
      when size + 1 < @publish_size do
    {:noreply, %{state | logs: {size + 1, [log | logs]}}}
  end

  def handle_cast({:publish, log}, %{logs: {size, logs}, timer: timer}) do
    do_publish(size + 1, [log | logs])
    Process.cancel_timer(timer)
    {:noreply, %{logs: {0, []}, timer: schedule_publishing()}}
  end

  @impl true
  def handle_info(:publish, %{logs: {size, logs}}) do
    do_publish(size, logs)
    {:noreply, %{logs: {0, []}, timer: schedule_publishing()}}
  end

  defp schedule_publishing do
    Process.send_after(self(), :publish, @publish_interval)
  end

  defp do_publish(0, _logs), do: :ok

  defp do_publish(size, logs) do
    Logger.info("Logging #{size} operations...")

    logs
    |> Enum.join("\n")
    |> write_to_influxdb()
  end

  defp write_to_influxdb(data) do
    Finch.build(:post, influxdb_url("/write?db=calc"), [], data)
    |> Finch.request(Calc.Log.Finch)
    |> parse_response()
  end

  defp influxdb_url(path), do: influxdb_base_url() <> path

  defp influxdb_base_url do
    Application.fetch_env!(:calc, Calc.Log)
    |> Keyword.fetch!(:influxdb_base_url)
  end

  defp parse_response({:ok, _}) do
    Logger.info("Operations logged")
    :ok
  end

  defp parse_response({:error, reason} = error) do
    Logger.info("Couldn't log operations: #{inspect(reason)}")
    error
  end
end
