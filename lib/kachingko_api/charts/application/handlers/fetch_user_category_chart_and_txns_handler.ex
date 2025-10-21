defmodule KachingkoApi.Charts.Application.Handlers.FetchUserCategoryChartAndTxnsHandler do
  alias KachingkoApi.Charts.Application.Commands.FetchUserCategoryChartAndTxns

  def handle(%FetchUserCategoryChartAndTxns{} = command, deps) do
    deps.repo.fetch_user_category_chart_and_txns(
      command.user_id,
      command.start_date,
      command.end_date
    )
  end
end
