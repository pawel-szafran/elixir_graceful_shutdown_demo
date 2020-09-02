defmodule Calc.SlowMath do
  def sum(numbers) when is_list(numbers) do
    Process.sleep(100)
    Enum.sum(numbers)
  end
end
