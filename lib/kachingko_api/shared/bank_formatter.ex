defmodule KachingkoApi.Shared.BankFormatter do
  def format(bank_name) when is_binary(bank_name) do
    bank_name
    |> String.replace("rcbc", "RCBC")
    |> String.replace("eastwest", "EastWest")
  end

  def format(bank_name), do: bank_name
end
