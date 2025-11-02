defmodule KachingkoApiWeb.StatementsController do
  use KachingkoApiWeb, :controller

  alias KachingkoApi.Shared.Errors
  alias KachingkoApi.Statements

  def list_txns(conn, params) do
    user = Guardian.Plug.current_resource(conn)

    # convert map to keyword list with atom keys
    params = Enum.map(Map.to_list(params), fn {k, v} -> {String.to_existing_atom(k), v} end)

    case Statements.list_user_transaction(user.id, params) do
      {:ok, %{metadata: metadata, entries: entries}} ->
        json(conn, %{
          success: true,
          data: %{
            metadata: Map.from_struct(metadata),
            entries: Enum.map(entries, &Map.from_struct/1)
          }
          # metadata: %{},
          # entries: []
        })

      {:error, :invalid_cursor} ->
        conn
        |> put_status(400)
        |> json(%{
          success: false,
          error: "Invalid paginated page"
        })
    end
  end

  def month_summay_spent(conn, params) do
    user = Guardian.Plug.current_resource(conn)
    # Process.sleep(Enum.random(500..5000))

    case Statements.month_summary_spent(user.id, params["start_date"], params["end_date"]) do
      {:ok, summary} ->
        json(conn, %{success: true, data: Map.from_struct(summary)})

      {:error, error} when is_map(error) ->
        IO.inspect(error)
        {_, error} = Map.to_list(error) |> List.first()

        conn
        |> put_status(400)
        |> json(%{success: false, error: error})
    end
  end

  def get_cards(conn, _params) do
    user = Guardian.Plug.current_resource(conn)

    case Statements.list_user_cards(user.id) do
      {:ok, list} ->
        json(conn, %{success: true, data: Enum.map(list, &Map.from_struct/1)})

      _ ->
        conn
        |> put_status(:bad_request)
        |> json(%{success: false, error: "Something went wrong. Please try again later."})
    end
  end

  def new_card(conn, params) do
    user = Guardian.Plug.current_resource(conn)
    params = Map.put(params, "user_id", user.id)

    case Statements.create_new_card(params) do
      {:ok, record} ->
        json(conn, %{success: true, data: Map.from_struct(record)})

      {:error, %Errors.ValidationError{message: error}} ->
        conn
        |> put_status(:bad_request)
        |> json(%{success: false, error: error})

      {:error, error} ->
        {_, error} = Map.to_list(error) |> List.first()

        conn
        |> put_status(:bad_request)
        |> json(%{success: false, error: error})
    end
  end

  def upload(conn, params) do
    user = Guardian.Plug.current_resource(conn)
    params = Map.put(params, "user_id", user.id)

    # Process.sleep(Enum.random(1000..2500))

    case Statements.upload_and_save_transactions_from_attachment(params) do
      {:ok, data} ->
        json(conn, %{
          success: true,
          data: Enum.map(data, &Map.from_struct(&1))
        })

      {:error, {:invalid_file_type, _}} ->
        conn
        |> put_status(:bad_request)
        |> json(%{success: false, error: "Please only upload .pdf files"})

      {:error, {:duplicate_statement, _}} ->
        conn
        |> put_status(:bad_request)
        |> json(%{success: false, error: "Transactions already exists"})

      {:error, {:max_size, _}} ->
        conn
        |> put_status(:bad_request)
        |> json(%{success: false, error: "File is too large"})

      {:error, ~c"Incorrect password"} ->
        conn
        |> put_status(:bad_request)
        |> json(%{success: false, error: "Incorrect statement .pdf password"})

      {:error, :malformed_extracted_text} ->
        conn
        |> put_status(:bad_request)
        |> json(%{success: false, error: "There is a problem parsing the .pdf statement"})

      # Ecto Error
      {:error, error} when is_map(error) ->
        {_, error} = Map.to_list(error) |> List.first()

        conn
        |> put_status(:bad_request)
        |> json(%{success: false, error: error})

      {:error, error} ->
        conn
        |> put_status(:bad_request)
        |> json(%{success: false, error: error})
    end
  end
end
