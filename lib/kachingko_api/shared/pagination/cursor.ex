defmodule KachingkoApi.Shared.Pagination.Cursor do
  def encode(last_record, sort_fields) when not is_nil(last_record) do
    position =
      sort_fields
      |> Enum.reduce(%{}, fn {field, _direction}, acc ->
        value = Map.get(last_record.transaction, field)
        Map.put(acc, Atom.to_string(field), serialize_value(value))
      end)

    position
    |> Jason.encode!()
    |> Base.encode64(padding: false)
  end

  def decode(nil), do: {:ok, nil}

  def decode(cursor_token) when is_binary(cursor_token) do
    with {:ok, json} <- Base.decode64(cursor_token, padding: false),
         {:ok, position} <- Jason.decode(json) do
      {:ok, deserialize_position(position)}
    else
      _ -> {:error, :invalid_cursor}
    end
  end

  def serialize_value(%DateTime{} = dt), do: DateTime.to_iso8601(dt)
  def serialize_value(%NaiveDateTime{} = dt), do: NaiveDateTime.to_iso8601(dt)
  def serialize_value(%Decimal{} = decimal), do: Decimal.to_string(decimal)
  def serialize_value(uuid), do: Ecto.UUID.cast!(uuid)

  def deserialize_position(position) do
    Map.new(position, fn {key, value} ->
      {String.to_atom(key), deserialize_value(value)}
    end)
  end

  defp deserialize_value(value) when is_binary(value) do
    cond do
      Regex.match?(~r/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}/, value) ->
        case DateTime.from_iso8601(value) do
          {:ok, dt, _} -> dt
          _ -> value
        end

      Regex.match?(~r/^\d+\.\d+$/, value) ->
        case Decimal.new(value) do
          %Decimal{} = d -> d
          _ -> value
        end

      Regex.match?(~r/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i, value) ->
        case Ecto.UUID.cast(value) do
          {:ok, uuid} -> uuid
          _ -> value
        end

      true ->
        value
    end
  end

  defp deserialize_value(value), do: value
end
