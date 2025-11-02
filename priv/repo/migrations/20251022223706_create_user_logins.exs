defmodule KachingkoApi.Repo.Migrations.CreateUserLogins do
  use Ecto.Migration

  def change do
    create table(:user_login, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :user_id, references(:user, type: :integer, on_delete: :delete_all), null: false

      # Authentication details
      # add :sign_in_count_at_time, :integer, null: false, default: 0
      add :signed_in_at, :utc_datetime, null: false
      add :ip_address, :string
      # add :user_agent, :string

      # JWT ID for token revocation
      add :token_jti, :string
      add :token_expires_at, :utc_datetime

      # Device fingerprinting
      add :device_fingerprint, :string

      # Session management
      add :session_id, :string
      add :is_active, :boolean, default: true
      add :signed_out_at, :utc_datetime

      # # Security flags
      # add :is_suspicious, :boolean, default: false
      # add :suspicious_reasons, {:array, :string}
      #
      # # Location (optional, can be enriched async)
      # add :country, :string
      # add :city, :string
      # add :location_data, :map
    end

    create index(:user_login, [:user_id])
    create index(:user_login, [:device_fingerprint])
    create index(:user_login, [:session_id])
    create index(:user_login, [:token_jti])
  end
end
