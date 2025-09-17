defmodule KachingkoApi.Statements.Domain.Services.ListUserTransactionService do
  alias KachingkoApi.Shared.Result

  alias KachingkoApi.Statements.Application.Commands.ListUserTransaction,
    as: ListUserTransactionCommand

  def list_user_transaction(%ListUserTransactionCommand{} = command, deps) do
    with {:ok, queryable} <- build_base_query(command, deps) do
      queryable
    end
  end

  defp build_base_query(%ListUserTransactionCommand{} = command, deps) do
    Result.ok(deps.txn_repository.list_user_transaction(command.user_id))
  end
end
