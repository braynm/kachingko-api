defmodule KachingkoApi.Charts.Domain.Dtos.FetchUserCategoryChartAndTxns do
  alias KachingkoApi.Shared.Result
  alias KachingkoApi.Shared.BankFormatter

  @type t :: %__MODULE__{
          categories: [map()] | nil,
          prev_month_total_amount: integer(),
          cur_month_total_amount: integer(),
          cur_month_txns: [map()] | nil
        }

  defstruct [:categories, :prev_month_total_amount, :cur_month_total_amount, :cur_month_txns]

  def new(chart) when is_map(chart) do
    Result.ok(%__MODULE__{
      prev_month_total_amount: convert_decimal(chart["prev_month_total_amount"]),
      cur_month_total_amount: convert_decimal(chart["cur_month_total_amount"]),
      categories: chart["categories"],
      cur_month_txns:
        Enum.map(chart["cur_month_txns"], fn txn ->
          Map.put(txn, "card", "#{BankFormatter.format(txn["card"])}")
        end)
    })
  end

  defp convert_decimal(nil), do: "0"

  defp convert_decimal(%Decimal{} = amt) do
    amt
    |> Decimal.to_string()
  end
end
