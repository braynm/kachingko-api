defmodule KachingkoApi.Statements.Domain.CardStatementRepo do
  @type t :: module()

  @callback find_by_checksum(integer, binary()) :: map() | nil
  @callback save_statement(map()) :: {:ok, map()} | {:error, map()}
end
