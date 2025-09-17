defmodule KachingkoApi.Repo.Migrations.TransactionMeta do
  use Ecto.Migration

  def change do
    create table(:transaction_meta, primary_key: false) do
      add(:id, :uuid, primary_key: true, null: false, default: fragment("uuid_generate_v4()"))
      add :transaction_id, references(:transaction, type: :uuid, on_delete: :delete_all)
      add :details, :string
      add :amount, :bigint

      timestamps(default: fragment("now()"))
    end
  end
end
