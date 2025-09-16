defmodule KachingkoApi.Statements.Application.Handlers.MonthSummarySpentHandler do
  alias KachingkoApi.Statements.Domain.Dtos.MonthSummarySpent
  alias KachingkoApi.Statements.Application.Commands.MonthSummarySpent

  def handle(%MonthSummarySpent{} = command, deps) do
    deps.repo.get_report_by_user_and_date(
      command.user_id,
      command.start_date,
      command.end_date
    )
  end
end
