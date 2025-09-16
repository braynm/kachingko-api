defmodule KachingkoApi.EncryptedTypes do
  @moduledoc """
  Custom Ecto types for encrypted fields
  """

  defmodule Binary do
    use Cloak.Ecto.Binary, vault: KachingkoApi.Vault
  end

  defmodule Money do
    use Cloak.Ecto.Type, vault: KachingkoApi.Vault
    alias KachingkoApi.Statements.Domain.ValueObjects.Amount

    def cast(value) when is_binary(value) do
      case Decimal.new(value) do
        %Decimal{} = decimal -> {:ok, decimal}
        _ -> :error
      end
    end

    def cast(%Decimal{} = value) do
      {:ok, value}
    end

    def cast(_), do: :error

    def dump(%Amount{amount: value}) do
      case Decimal.to_string(value) do
        string when is_binary(string) -> {:ok, string}
        _ -> :error
      end
    end

    def load(value) do
      Amount.from_db(value)
    end
  end
end
