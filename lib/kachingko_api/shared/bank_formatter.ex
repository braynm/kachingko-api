defmodule KachingkoApi.Shared.BankFormatter do
  @moduledoc """
  BankFormatter module is for formatting supported banks.

    iex> BankFormatter.format(bank_name)
  """
  def format(bank_name) when is_binary(bank_name) do
    bank_name
    |> String.replace("rcbc", "RCBC")
    |> String.replace("eastwest", "EastWest")
  end

  def format(bank_name), do: bank_name
end
