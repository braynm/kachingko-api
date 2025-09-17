defmodule KachingkoApi.Statements.Domain.TransactionRepo do
  @type t :: module()
  @callback create_batch_transaction(map()) :: {:ok, [map()]} | {:error, map()}
end
