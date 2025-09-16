defmodule KachingkoApi.Charts.Application.Handlers.FetchUserChartsHandler do
  alias KachingkoApi.Charts.Application.Commands.FetchUserCharts

  def handle(%FetchUserCharts{} = command, deps) do
    IO.inspect(deps)

    deps.repo.fetch_user_charts(
      command.user_id,
      command.start_date,
      command.end_date
    )
  end
end
