defmodule CalcWeb.Router do
  use CalcWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", CalcWeb do
    pipe_through :api

    post "/sum", CalcController, :sum
  end
end
