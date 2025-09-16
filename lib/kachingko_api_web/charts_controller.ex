defmodule KachingkoApiWeb.ChartsController do
  use KachingkoApiWeb, :controller

  alias KachingkoApi.Shared.Errors
  alias KachingkoApi.Charts

  def fetch_user_charts(conn, params) do
    user = Guardian.Plug.current_resource(conn)
    params = Map.put_new(params, "user_id", user.id)

    Process.sleep(Enum.random(500..2500))

    case Charts.find_user_charts(params) |> IO.inspect() do
      {:error, error} ->
        conn
        |> put_status(:bad_request)
        |> json(%{success: false, error: error})

      {:ok, data} when is_struct(data) ->
        json(conn, %{success: true, data: Map.from_struct(data)})

      _ ->
        json(conn, %{success: false, error: "Something went wrong. Please try again later."})

        # {:ok, %{metadata: metadata, entries: entries}} ->
        #   json(conn, %{
        #     success: true,
        #     data: %{
        #       metadata: Map.from_struct(metadata),
        #       entries: Enum.map(entries, &Map.from_struct/1)
        #     }
        #     # metadata: %{},
        #     # entries: []
        #   })
        #
        # {:error, :invalid_cursor} ->
        #   conn
        #   |> put_status(400)
        #   |> json(%{
        #     success: false,
        #     error: "Invalid paginated page"
        #   })
    end
  end
end
