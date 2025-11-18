defmodule KachingkoApi.LoginTracking.Infra.Schemas.UserLoginschema do
  use Ecto.Schema
  import Ecto.Changeset
  alias KachingkoApi.LoginTracking.Application.Entities.LoginDevice

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "user_login" do
    field :user_id, :integer
    field :signed_in_at, :utc_datetime
    field :ip_address, :string
    field :token_jti, :string
    field :token_expires_at, :utc_datetime
    field :device_fingerprint, :string
    field :session_id, :string
    field :signed_out_at, :utc_datetime
  end

  def changeset(attrs) do
    schema_map = %{
      user_id: attrs.user_id,
      signed_in_at: attrs.signed_in_at,
      ip_address: attrs.ip_address,
      token_jti: attrs.token_jti,
      token_expires_at: attrs.token_expires_at,
      device_fingerprint: attrs.fingerprint,
      session_id: attrs.session_id,
      signed_out_at: attrs.signed_out_at
    }

    %__MODULE__{}
    |> cast(schema_map, [
      :user_id,
      :signed_in_at,
      :ip_address,
      :token_jti,
      :token_expires_at,
      :device_fingerprint,
      :session_id,
      :signed_out_at
    ])
    |> validate_required([
      :user_id,
      :signed_in_at,
      :ip_address,
      :token_jti,
      :token_expires_at,
      :device_fingerprint,
      :session_id
    ])
  end
end
