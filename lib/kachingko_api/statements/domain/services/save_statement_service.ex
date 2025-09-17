defmodule KachingkoApi.Statements.Domain.Services.SaveStatementService do
  alias KachingkoApi.Statements.Infra.EctoTransactionRepository
  alias KachingkoApi.Statements.Infra.EctoTransactionMetaRepository
  alias KachingkoApi.Statements.Infra.EctoCardStatementRepository

  alias KachingkoApi.Statements.Domain.ValueObjects.FileChecksum
  alias KachingkoApi.Statements.Domain.Entities.CardStatement
  alias KachingkoApi.Statements.Domain.Entities.Transaction
  alias KachingkoApi.Statements.Domain.Entities.TransactionMeta

  def save_statement_and_transaction(params) do
    txns = params["txns"]
    user_id = params["user_id"]
    %FileChecksum{value: checksum} = params["file_checksum"]

    card_stmt =
      params
      |> Map.take(["filename", "file_checksum", "user_id", "card_id"])
      |> Map.put("file_checksum", checksum)

    with {:ok, statement_entity} <- CardStatement.new(card_stmt),
         {:ok, inserted_stmt} <- save_statement(statement_entity),
         {:ok, batch_txns} <- map_batch_txns(user_id, inserted_stmt.id, txns) do
      batch_insert_txns(batch_txns)
    end
  end

  defp save_statement(statement_entity) do
    EctoCardStatementRepository.save_statement(statement_entity)
  end

  defp map_batch_txns(user_id, statement_id, txns) do
    txn_items =
      Enum.map(
        txns,
        &Map.merge(&1, %{
          user_id: user_id,
          statement_id: statement_id
        })
      )

    {:ok, txn_items}
  end

  defp batch_insert_txns(txns) do
    with {:ok, inserted_txns} <-
           EctoTransactionRepository.create_batch_transaction(txns) do
      txn_metas = Enum.map(inserted_txns, &to_txn_metas_entity/1)

      # side effect for reports
      {:ok, _} = EctoTransactionMetaRepository.create_batch_transaction(txn_metas)
      {:ok, inserted_txns}
    end
  end

  defp to_txn_metas_entity(%Transaction{} = item) do
    {:ok, txn_meta} = TransactionMeta.from_transaction(item)

    txn_meta
    |> Map.from_struct()
    |> Map.put(:id, Ecto.UUID.generate())
  end
end
