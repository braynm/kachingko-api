defmodule KachingkoApi.Authentication.Infra.Schemas.UserSchema do
  use Ecto.Schema
  import Ecto.Changeset

  schema "user" do
    field :email, :string
    field :password_hash, :string
    field :two_factor_enabled, :boolean
    field :two_factor_secret, KachingkoApi.EncryptedTypes.Binary
    field :two_factor_method, :string
    field :two_factor_backup_codes, {:array, :string}

    timestamps()
  end

  def changeset(user, attrs) do
    user
    |> cast(attrs, [:email, :password_hash])
    |> validate_required([:email, :password_hash])
    |> unique_constraint(:email)
  end

  def two_factor_changeset(user, attrs) do
    user
    |> cast(attrs, [
      :two_factor_enabled,
      :two_factor_method,
      :two_factor_secret,
      :two_factor_backup_codes
    ])
    |> validate_required([
      :two_factor_enabled,
      :two_factor_method,
      :two_factor_secret,
      :two_factor_backup_codes
    ])
  end
end
