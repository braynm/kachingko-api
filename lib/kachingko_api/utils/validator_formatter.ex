defmodule KachingkoApi.Utils.ValidatorFormatter do
  def first_error(changeset) do
    changeset.errors
  end

  def first_errors_by_field(changeset) do
    changeset.errors
    |> Enum.reduce(%{}, fn {field, error}, acc ->
      case Map.has_key?(acc, field) do
        # Skip if we already have an error for this field
        true -> acc
        false -> Map.put(acc, field, format_error(error))
      end
    end)
  end

  defp format_error({message, opts}) do
    Enum.reduce(opts, message, fn {key, value}, acc ->
      String.replace(acc, "%{#{key}}", to_string(value))
    end)
  end

  defp format_error(message) when is_binary(message), do: message
end
