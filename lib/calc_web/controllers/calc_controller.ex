defmodule CalcWeb.CalcController do
  use CalcWeb, :controller

  def sum(conn, %{"numbers" => numbers}) when is_list(numbers) do
    result =
      numbers
      |> Enum.filter(&is_number/1)
      |> Calc.sum()

    render(conn, "result.json", result: result)
  end
end
