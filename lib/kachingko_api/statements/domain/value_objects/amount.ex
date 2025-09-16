defmodule KachingkoApi.Statements.Domain.ValueObjects.Amount do
  @moduledoc """
  Amount value object for PHP currency only
  All amounts are assumed to be in Philippine Peso (PHP)
  """

  defstruct [:amount]

  @type t :: %__MODULE__{
          amount: Decimal.t()
        }

  def new(amount) when is_binary(amount) do
    # Remove common formatting: commas, currency symbols
    clean_amount =
      amount
      |> String.replace(~r/[,₱$]/, "")
      |> String.trim()

    case Decimal.new(clean_amount) do
      %Decimal{} = decimal ->
        storage_value = mult_by_100(decimal)
        {:ok, %__MODULE__{amount: storage_value}}

      _ ->
        {:error, :invalid_amount}
    end
  end

  def new(%Decimal{} = amount) do
    storage_value = mult_by_100(amount)
    {:ok, %__MODULE__{amount: storage_value}}
  end

  def new(amount) when is_integer(amount) do
    storage_value = Decimal.new(amount) |> mult_by_100()
    {:ok, %__MODULE__{amount: storage_value}}
  end

  def new(amount) when is_float(amount) do
    storage_value = Decimal.from_float(amount) |> mult_by_100()
    {:ok, %__MODULE__{amount: storage_value}}
  end

  def new(_), do: {:error, :invalid_amount}

  # returns an unformatted and normalized value e.g. (12050 -> 120.50)
  def from_db(amount) when is_binary(amount) do
    amount =
      amount
      |> Decimal.new()
      |> div_by_100()
      |> Decimal.to_string(:normal)

    {:ok, amount}
  end

  defp mult_by_100(%Decimal{} = amount) do
    Decimal.mult(amount, 100) |> Decimal.round()
  end

  defp div_by_100(%Decimal{} = amount) do
    Decimal.div(amount, 100)
  end

  def to_decimal(%__MODULE__{amount: amount}), do: amount

  def to_string(%__MODULE__{amount: amount}) do
    Decimal.to_string(amount, :normal)
  end

  def to_currency_string(%__MODULE__{amount: amount}) do
    formatted =
      amount
      |> div_by_100()
      |> Decimal.to_string(:normal)
      |> format_with_commas()

    # "₱#{formatted}"
    "#{formatted}"
  end

  defp format_with_commas(amount_string) do
    [integer_part, decimal_part] =
      case String.split(amount_string, ".") do
        [integer] -> [integer, "00"]
        [integer, decimal] -> [integer, String.pad_trailing(decimal, 2, "0")]
      end

    formatted_integer =
      integer_part
      |> String.reverse()
      |> String.replace(~r/(\d{3})(?=\d)/, "\\1,")
      |> String.reverse()

    "#{formatted_integer}.#{decimal_part}"
  end
end
