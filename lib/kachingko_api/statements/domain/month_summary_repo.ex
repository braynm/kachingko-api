defmodule KachingkoApi.Statements.Domain.MonthSummarySpentRepo do
  @type t :: module()
  @callback get_report_by_user_and_date(integer(), Date.t(), Date.t()) ::
              {:ok, map()} | {:error, map()}
end
