defmodule KachingkoApi.Statements.Infra.EctoMonthSummarySpentRepository do
  @behaviour KachingkoApi.Statements.Domain.MonthSummarySpentRepo

  alias KachingkoApi.Repo
  alias KachingkoApi.Shared.Result
  alias KachingkoApi.Statements.Domain.Dtos.MonthSummarySpent

  @impl true
  def get_report_by_user_and_date(user_id, start_date, end_date) do
    query = "SELECT * FROM kachingko_month_summary_spent($1, $2, $3)"

    with {:ok, %Postgrex.Result{rows: [rows], columns: columns}} <-
           Repo.query(query, [user_id, start_date, end_date]) do
      Enum.zip(columns, rows)
      |> Enum.into(%{})
      |> MonthSummarySpent.new()
      |> Result.ok()
    end
  end
end
