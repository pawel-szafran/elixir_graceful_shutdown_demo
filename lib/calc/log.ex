defmodule Calc.Log do
  require Logger

  def publish_async(op, numbers, result) do
    Logger.info("Logging operation... ")
    numbers = length(numbers)

    Task.start(fn ->
      publish(op, numbers, result)
    end)
  end

  defp publish(op, numbers, result) do
    Process.sleep(5_000)
    write_to_influxdb("operation,name=#{op} numbers=#{numbers},result=#{result}")
  end

  defp write_to_influxdb(log) do
    Finch.build(:post, influxdb_url("/write?db=calc"), [], log)
    |> Finch.request(CalcFinch)
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
