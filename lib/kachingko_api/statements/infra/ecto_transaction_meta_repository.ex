defmodule KachingkoApi.Statements.Infra.EctoTransactionMetaRepository do
  @behaviour KachingkoApi.Statements.Domain.TransactionRepo

  alias KachingkoApi.Repo
  alias KachingkoApi.Statements.Infra.Schemas.TransactionMetaSchema

  def create_batch_transaction(txn_metas) do
    case Repo.insert_all(TransactionMetaSchema, txn_metas, returning: true) do
      {:error, changeset} -> {:error, changeset}
      {_, inserted_txns} -> {:ok, inserted_txns}
    end
  end
end
