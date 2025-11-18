defmodule KachingkoApi.Repo.Migrations.Users2FA do
  use Ecto.Migration

  def change do
    alter table(:user) do
      add :two_factor_enabled, :boolean, default: false, null: false
      add :two_factor_secret, :binary
      add :two_factor_method, :string, default: "totp"
      add :two_factor_backup_codes, {:array, :string}
    end
  end
end
