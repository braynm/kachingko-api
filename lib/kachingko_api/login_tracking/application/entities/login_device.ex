defmodule KachingkoApi.LoginTracking.Application.Entities.LoginDevice do
  alias KachingkoApi.Shared.Result
  alias KachingkoApi.LoginTracking.Application.Commands.LoginDevice, as: LoginDeviceCommand
  alias KachingkoApi.LoginTracking.Infra.Schemas.KnownDeviceSchema

  @type t :: %__MODULE__{
          id: String.t() | nil,
          user_id: String.t(),
          ip_address: String.t(),
          fingerprint: map(),
          # info: String.t(),

          screen_resolution: String.t(),
          timezone: String.t(),
          language: String.t(),
          browserName: String.t(),
          osName: String.t(),
          platform: String.t(),
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  defstruct [
    :id,
    :user_id,
    :ip_address,
    :fingerprint,
    # :info
    :screen_resolution,
    :timezone,
    :language,
    :browserName,
    :osName,
    :platform,
    :inserted_at,
    :updated_at
  ]

  def new(%LoginDeviceCommand{} = params, user_id) when is_integer(user_id) do
    Result.ok(%__MODULE__{
      id: nil,
      user_id: user_id,
      fingerprint: params.fingerprint,
      ip_address: params.ip_address,
      # info: %{
      screen_resolution: params.screen_resolution,
      timezone: params.timezone,
      language: params.language,
      browserName: params.browserName,
      osName: params.osName,
      platform: params.platform
      # }
    })
  end

  def new(_, _), do: Result.error(:invalid_parameters)

  def from_schema(%KnownDeviceSchema{} = schema) do
    Result.ok(%__MODULE__{
      id: schema.id,
      user_id: schema.user_id,
      fingerprint: schema.device_fingerprint,
      ip_address: schema.device_info["ip_address"],
      screen_resolution: schema.device_info["screen_resolution"],
      timezone: schema.device_info["timezone"],
      language: schema.device_info["language"],
      browserName: schema.device_info["browserName"],
      osName: schema.device_info["osName"],
      platform: schema.device_info["platform"],
      inserted_at: schema.inserted_at,
      updated_at: schema.updated_at
    })
  end

  def is_device_unknown?(%__MODULE__{} = entity) do
    cond do
      is_nil(entity.inserted_at) or is_nil(entity.updated_at) -> true
      DateTime.compare(entity.inserted_at, entity.updated_at) == :eq -> true
      true -> false
    end
  end
end
