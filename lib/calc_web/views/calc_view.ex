defmodule CalcWeb.CalcView do
  use CalcWeb, :view

  def render("result.json", %{result: result}) do
    %{result: result}
  end
end
