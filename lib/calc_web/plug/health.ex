defmodule CalcWeb.Plug.Health do
  use Plug.Router

  plug(:match)
  plug(:dispatch)

  get "/health" do
    halt_with_json(conn, 200, %{status: :healthy})
  end

  match _ do
    conn
  end

  defp halt_with_json(conn, status, body) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(status, Jason.encode!(body))
    |> halt()
  end
end
