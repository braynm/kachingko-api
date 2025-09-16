defmodule KachingkoApi.Statements.Infra.Schemas.CardStatementSchema do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "card_statement" do
    field :user_id, :integer
    field :card_id, Ecto.UUID
    field :filename, :string
    field :file_checksum, :string

    # TODO: add covered date? e.g. 2024-01-01 to 2024-02-01

    timestamps()
  end

  def changeset(%__MODULE__{} = card_statement, attrs) do
    card_statement
    |> cast(attrs, [:user_id, :card_id, :file_checksum, :filename])
    |> validate_required([:user_id, :card_id, :file_checksum, :filename])
  end
end
