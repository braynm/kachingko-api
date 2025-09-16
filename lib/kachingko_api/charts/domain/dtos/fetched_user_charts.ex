defmodule KachingkoApi.Charts.Domain.Dtos.FetchedUserCharts do
  alias KachingkoApi.Shared.Result
  alias KachingkoApi.Shared.BankFormatter

  @type t :: %__MODULE__{
          ytd_amount: String.t() | nil,
          monthly_avg: String.t() | nil,
          highest_purchase: String.t() | nil,
          overall_amount: String.t() | nil,
          monthly_expenses: [map()] | nil,
          top_expenses: [map()] | nil
        }

  defstruct [
    :ytd_amount,
    :monthly_avg,
    :highest_purchase,
    :overall_amount,
    :monthly_expenses,
    :top_expenses
  ]

  def new(chart) when is_map(chart) do
    IO.inspect(chart)

    Result.ok(%__MODULE__{
      ytd_amount: convert_decimal(chart["ytd_amount"]),
      monthly_avg: convert_decimal(chart["monthly_avg"]),
      highest_purchase: convert_decimal(chart["highest_purchase"]),
      overall_amount: convert_decimal(chart["overall_amount"]),
      monthly_expenses:
        Enum.map(
          chart["monthly_expenses"],
          &Map.put(&1, "name", BankFormatter.format(&1["name"]))
        ),
      top_expenses: chart["top_expenses"]
    })
  end

  defp convert_decimal(nil), do: "0"

  defp convert_decimal(%Decimal{} = amt) do
    amt
    |> Decimal.to_string()
  end
end
