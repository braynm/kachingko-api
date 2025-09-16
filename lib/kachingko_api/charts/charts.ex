defmodule KachingkoApi.Charts do
  alias KachingkoApi.Charts.Infra.EctoUserChartsRepository
  alias KachingkoApi.Charts.Application.Commands.FetchUserCharts
  alias KachingkoApi.Charts.Application.Handlers.FetchUserChartsHandler

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
end
