defmodule KachingkoApi.Statements.Domain.Dtos.MonthSummarySpent do
  alias KachingkoApi.Shared.Result

  @type t :: %__MODULE__{
          date: Date.t(),
          spent_pct: String.t(),
          daily_spent: [any()]
        }

  defstruct [:date, :spent_pct, :daily_spent]

  def new(report) when is_map(report) do
    Result.ok(%__MODULE__{
      date: Date.to_string(report["day_date"]),
      daily_spent:
        Enum.map(report["daily_spent"], fn item ->
          # %{amount: item["amount"], date: item["day_date"]}
          item["amount"]
        end),
      spent_pct: convert_to_string(report["spent_pct"])
    })
  end

  defp convert_to_string(nil), do: "-"

  defp convert_to_string(%Decimal{} = decimal) do
    Decimal.to_string(decimal)
  end
end
