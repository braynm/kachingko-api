defmodule KachingkoApi.Statements do
  alias KachingkoApi.Statements.Application.Commands.UploadStatementTransaction
  alias KachingkoApi.Statements.Application.Handlers.UploadStatementHandler
  alias KachingkoApi.Statements.Domain.Services.StatementProcessingServices

  alias KachingkoApi.Statements.Domain.Services.ListUserTransaction
  alias KachingkoApi.Statements.Application.Handlers.ListUserTransactionHandler
  alias KachingkoApi.Statements.Application.Handlers.MonthSummarySpentHandler

  alias KachingkoApi.Statements.Application.Commands.ListUserTransaction
  alias KachingkoApi.Statements.Application.Commands.MonthSummarySpent

  alias KachingkoApi.Statements.Infra.EctoMonthSummarySpentRepository

  alias KachingkoApi.Statements.Infra.EctoCardRepository

  alias KachingkoApi.Statements.Application.Commands.CreateNewCard
  alias KachingkoApi.Statements.Application.Handlers.CreateNewCardHandler
  alias KachingkoApi.Statements.Application.Handlers.GetCardsHandler

  def upload_and_save_transactions_from_attachment(params, deps \\ statement_process_deps())

  def upload_and_save_transactions_from_attachment(params, deps) do
    with {:ok, command} <- UploadStatementTransaction.new(params) do
      UploadStatementHandler.handle(command, deps)
    end
  end

  def create_new_card(params, deps \\ card_deps())

  def create_new_card(params, deps) do
    with {:ok, command} <- CreateNewCard.new(params) do
      CreateNewCardHandler.handle(command, deps)
    end
  end

  def list_user_cards(user_id, deps \\ card_deps())

  def list_user_cards(user_id, deps) do
    GetCardsHandler.handle(user_id, deps)
  end

  def list_user_transaction(user_id, params \\ [], deps \\ list_txns_deps())

  def list_user_transaction(user_id, params, deps) do
    params = Keyword.put(params, "user_id", user_id)

    with {:ok, command} <- ListUserTransaction.new(params) do
      ListUserTransactionHandler.handle(command, deps)
    end
  end

  def month_summary_spent(user_id, start_date, end_date, deps \\ month_summary_spent_deps())

  def month_summary_spent(user_id, start_date, end_date, deps) do
    with {:ok, command} <-
           MonthSummarySpent.new(%{
             user_id: user_id,
             start_date: start_date,
             end_date: end_date
           }),
         {:ok, result} <- MonthSummarySpentHandler.handle(command, deps) do
      result
    end
  end

  defp month_summary_spent_deps do
    %{repo: EctoMonthSummarySpentRepository}
  end

  defp card_deps do
    %{repo: EctoCardRepository}
  end

  defp statement_process_deps, do: StatementProcessingServices.default()

  defp list_txns_deps do
    %StatementProcessingServices{
      txn_repository: txn_repository
    } = statement_process_deps()

    %{txn_repository: txn_repository}
  end
end
