defmodule KachingkoApi.LoginTracking.Infra.Schemas.KnownDeviceSchema do
  use Ecto.Schema
  import Ecto.Changeset
  alias KachingkoApi.LoginTracking.Application.Entities.LoginDevice

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "known_device" do
    field :user_id, :integer
    field :device_fingerprint, :string
    # screen resolution, timezone, language, browser name, os name, os version, platform
    field :device_info, :map

    timestamps()
  end

  def changeset(%LoginDevice{} = attrs) do
    schema_map = %{
      user_id: attrs.user_id,
      device_fingerprint: attrs.fingerprint,
      device_info: %{
        ip_address: attrs.ip_address,
        screen_resolution: attrs.screen_resolution,
        timezone: attrs.timezone,
        language: attrs.language,
        browserName: attrs.browserName,
        osName: attrs.osName,
        platform: attrs.platform
      }
    }

    %__MODULE__{}
    |> cast(schema_map, [:user_id, :device_fingerprint, :device_info])
    |> validate_required([:user_id, :device_fingerprint, :device_info])
  end
end
