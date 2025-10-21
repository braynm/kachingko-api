defmodule KachingkoApiWeb.ChartsController do
  use KachingkoApiWeb, :controller

  alias KachingkoApi.Charts

  def fetch_user_charts(conn, params) do
    user = Guardian.Plug.current_resource(conn)
    params = Map.put_new(params, "user_id", user.id)

    case Charts.find_user_charts(params) do
      {:error, error} ->
        conn
        |> put_status(:bad_request)
        |> json(%{success: false, error: error})

      {:ok, data} when is_struct(data) ->
        json(conn, %{success: true, data: Map.from_struct(data)})

      _ ->
        json(conn, %{success: false, error: "Something went wrong. Please try again later."})
    end
  end

  def fetch_category_chart_and_txns(conn, params) do
    user = Guardian.Plug.current_resource(conn)
    params = Map.put_new(params, "user_id", user.id)

    case Charts.find_user_category_chart_and_txns(params) do
      {:error, error} ->
        conn
        |> put_status(:bad_request)
        |> json(%{success: false, error: error})

      {:ok, data} when is_struct(data) ->
        json(conn, %{success: true, data: Map.from_struct(data)})

      _ ->
        json(conn, %{success: false, error: "Something went wrong. Please try again later."})
    end
  end
end
