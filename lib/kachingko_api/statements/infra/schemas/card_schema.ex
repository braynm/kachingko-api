defmodule KachingkoApi.Statements.Infra.Schemas.CardSchema do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "card" do
    field :user_id, :integer
    field :bank, :string
    field :name, :string

    timestamps()
  end

  def changeset(%__MODULE__{} = card, attrs) do
    card
    |> cast(attrs, [:user_id, :bank, :name])
    |> validate_required([:user_id, :bank, :name])
    |> unique_constraint([:user_id, :bank, :name], message: "Card already exists")
  end
end
