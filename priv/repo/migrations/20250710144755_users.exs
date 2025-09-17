defmodule KachingkoApi.Repo.Migrations.User do
  use Ecto.Migration

  def change do
    create table(:user) do
      add :email, :string, unique: true
      add :name, :string
      add :password_hash, :string

      timestamps()
    end

    create unique_index(:user, :email)
  end
end
