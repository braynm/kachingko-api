defmodule KachingkoApi.Statements.Application.Handlers.ListUserTransactionHandler do
  alias KachingkoApi.Shared.Result
  alias KachingkoApi.Shared.Pagination
  alias KachingkoApi.Statements.Domain.Dtos.UserTxn
  alias KachingkoApi.Shared.Pagination.PaginationParams
  alias KachingkoApi.Statements.Application.Commands.ListUserTransaction
  alias KachingkoApi.Statements.Domain.Services.ListUserTransactionService

  def handle(%ListUserTransaction{} = command, deps) do
    with {:ok, base_query} <- build_base_query(command, deps),
         {:ok, pagination_params} <- build_pagination_params(command, base_query),
         {:ok, pagination} <- Pagination.paginate(pagination_params, deps) do
      Result.ok(%{
        entries: list_to_txn_domain(pagination.entries),
        metadata: pagination.metadata
      })
    end
  end

  defp list_to_txn_domain(entries) when is_list(entries) do
    Enum.map(entries, &to_txn_domain/1)
  end

  defp to_txn_domain(entry) do
    {:ok, txn} = UserTxn.new(entry)
    txn
  end

  defp build_base_query(command, deps) do
    Result.ok(ListUserTransactionService.list_user_transaction(command, deps))
  end

  defp build_pagination_params(%ListUserTransaction{} = command, base_query) do
    filters = command.filters || %{}

    # TODO: make a fnction in  pagination to wrap and isolate this
    PaginationParams.new(base_query,
      cursor: command.cursor,
      filters: filters,
      limit: command.limit,
      sort: command.sort
    )
  end
end
