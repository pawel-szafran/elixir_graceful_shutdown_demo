defmodule Calc do
  alias __MODULE__.SlowMath
  require Logger

  def sum(numbers) when is_list(numbers) do
    Logger.info("Calculating sum of #{inspect(numbers)}")
    sum = SlowMath.sum(numbers)
    Logger.info("Sum is #{sum}")
    Calc.Log.publish_async(:sum, numbers, sum)
    sum
  end
end
