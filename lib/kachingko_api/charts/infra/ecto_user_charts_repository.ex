defmodule KachingkoApi.Charts.Infra.EctoUserChartsRepository do
  @behaviour KachingkoApi.Charts.Domain.Repositories.UserChartRepo

  alias KachingkoApi.Repo
  alias KachingkoApi.Charts.Domain.Dtos.FetchedUserCharts

  def fetch_user_charts(user_id, start_date, end_date) do
    query = "SELECT * FROM kachingko_totals($1, $2, $3)"

    with {:ok, %Postgrex.Result{rows: [rows], columns: columns}} <-
           Repo.query(query, [user_id, start_date, end_date]) do
      Enum.zip(columns, rows)
      |> Enum.into(%{})
      |> FetchedUserCharts.new()
    end
  end
end
