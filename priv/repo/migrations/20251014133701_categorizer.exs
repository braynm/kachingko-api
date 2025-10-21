defmodule KachingkoApi.Repo.Migrations.TransactionCategorizer do
  use Ecto.Migration

  def change do
    alter table(:transaction) do
      add :category, :string, default: "Other"
      add :subcategory, :string, default: nil
    end
  end
end
