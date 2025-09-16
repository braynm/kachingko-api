defmodule KachingkoApi.Statements.Infra.EctoTransactionRepository do
  @behaviour KachingkoApi.Statements.Domain.TransactionRepo

  import Ecto.Query
  alias KachingkoApi.Repo
  alias KachingkoApi.Statements.Domain.Entities.Transaction
  alias KachingkoApi.Statements.Infra.Schemas.TransactionSchema
  alias KachingkoApi.Statements.Infra.Schemas.CardSchema
  alias KachingkoApi.Statements.Infra.Schemas.CardStatementSchema

  def create_batch_transaction(txns) do
    case Repo.insert_all(TransactionSchema, txns, returning: true) do
      {:error, changeset} -> {:error, changeset}
      {_, inserted_txns} -> {:ok, Enum.map(inserted_txns, &to_domain/1)}
    end
  end

  defp to_domain(%TransactionSchema{} = schema) do
    {:ok, txn} = Transaction.from_schema(schema)
    txn
  end

  defp to_domain(params) do
    IO.inspect(params)
    # {:ok, txn} = Transaction.from_schema(schema)
    params
  end

  @spec list_user_transaction(integer()) :: Ecto.Queryable.t()
  def list_user_transaction(user_id) do
    from t in TransactionSchema,
      join: cs in CardStatementSchema,
      on: cs.id == t.statement_id,
      join: cc in CardSchema,
      on: cc.id == cs.card_id,
      where: t.user_id == ^user_id,
      select: %{transaction: t, card: cc}
  end

  @spec all(Ecto.Queryable.t()) :: [any()]
  def all(queryable) do
    Repo.all(queryable)
  end
end
