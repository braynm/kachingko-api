defmodule KachingkoApi.Charts.Domain.Repositories.UserChartRepo do
  @type t :: module()

  @callback fetch_user_charts(integer, Date.t(), Date.t()) :: map() | nil
end
