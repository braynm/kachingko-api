defmodule KachingkoApi.Charts.Infra.EctoUserChartsRepository do
  @behaviour KachingkoApi.Charts.Domain.Repositories.UserChartRepo

  alias KachingkoApi.Repo
  alias KachingkoApi.Charts.Domain.Dtos.FetchedUserCharts
  alias KachingkoApi.Charts.Domain.Dtos.FetchUserCategoryChartAndTxns

  def fetch_monthly_and_highest_txns_all_time(user_id, start_date, end_date) do
    query = "SELECT * FROM kachingko_totals($1, $2, $3)"

    with {:ok, %Postgrex.Result{rows: [rows], columns: columns}} <-
           Repo.query(query, [user_id, start_date, end_date]) do
      Enum.zip(columns, rows)
      |> Enum.into(%{})
      |> FetchedUserCharts.new()
    end
  end

  def fetch_user_charts(user_id, start_date, end_date) do
    fetch_monthly_and_highest_txns_all_time(user_id, start_date, end_date)
  end

  def fetch_user_category_chart_and_txns(user_id, start_date, end_date) do
    query = "SELECT * FROM kachingko_dashboard_category_chart($1, $2, $3)"

    with {:ok, %Postgrex.Result{rows: [rows], columns: columns}} <-
           Repo.query(query, [user_id, start_date, end_date]) do
      Enum.zip(columns, rows)
      |> Enum.into(%{})
      |> FetchUserCategoryChartAndTxns.new()
    end
  end
end
