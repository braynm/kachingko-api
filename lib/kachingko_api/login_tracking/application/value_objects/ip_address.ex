defmodule KachingkoApi.LoginTracking.Application.ValueObjects.IPAddress do
  defstruct [:value]

  def new(value) when is_binary(value) do
    case :inet.parse_address(String.to_charlist(value)) do
      {:ok, _} -> {:ok, %__MODULE__{value: value}}
      {:error, _} -> {:error, "must be valid IP Address"}
    end
  end

  def new(_value), do: {:error, :invalid_value}
end
