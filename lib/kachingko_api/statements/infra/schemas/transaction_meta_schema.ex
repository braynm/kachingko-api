defmodule KachingkoApi.Statements.Infra.Schemas.TransactionMetaSchema do
  use Ecto.Schema

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "transaction_meta" do
    field :transaction_id, Ecto.UUID
    field :details, :string
    field :amount, :integer

    timestamps()
  end
end
