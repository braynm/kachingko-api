defmodule KachingkoApi.Shared.BankFormatter do
  @supported_banks Application.get_env(:kachingko_api, :supported_banks)
  def format(bank_name) when is_binary(bank_name) and bank_name in @supported_banks do
    bank_name
    |> String.replace("rcbc", "RCBC")
    |> String.replace("eastwest", "EastWest")
  end

  def format(bank_name), do: bank_name
end
