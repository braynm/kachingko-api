defmodule KachingkoApi.Repo.Migrations.CreateKnownDevices do
  use Ecto.Migration

  def change do
    create table(:known_device, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :user_id, references(:user, type: :integer, on_delete: :delete_all), null: false

      add :device_fingerprint, :string, null: false
      add :device_info, :map

      add :total_logins, :integer, default: 1

      timestamps()
    end

    create unique_index(:known_device, [:user_id, :device_fingerprint])
    create index(:known_device, [:user_id])
    create index(:known_device, [:device_fingerprint])
  end
end
