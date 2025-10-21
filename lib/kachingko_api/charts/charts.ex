defmodule KachingkoApi.Charts do
  alias KachingkoApi.Charts.Infra.EctoUserChartsRepository

  alias KachingkoApi.Charts.Application.Handlers.FetchUserChartsHandler
  alias KachingkoApi.Charts.Application.Handlers.FetchUserCategoryChartAndTxnsHandler

  alias KachingkoApi.Charts.Application.Commands.FetchUserCharts
  alias KachingkoApi.Charts.Application.Commands.FetchUserCategoryChartAndTxns

  def find_user_charts(params, deps \\ charts_deps())

  def find_user_charts(params, deps) do
    with {:ok, command} <- FetchUserCharts.new(params) do
      FetchUserChartsHandler.handle(command, deps)
    end
  end

  defp charts_deps do
    %{
      repo: EctoUserChartsRepository
    }
  end

  def find_user_category_chart_and_txns(params, deps \\ charts_deps())

  def find_user_category_chart_and_txns(params, deps) do
    with {:ok, command} <- FetchUserCategoryChartAndTxns.new(params) do
      FetchUserCategoryChartAndTxnsHandler.handle(command, deps)
    end
  end
end
