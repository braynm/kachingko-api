defmodule KachingkoApi.LoginTracking.Application.Services.LoginTrackingService do
  alias KachingkoApi.LoginTracking.Infra.EctoUserLoginRepository
  alias KachingkoApi.LoginTracking.Application.Entities.LoginDevice
  alias KachingkoApi.LoginTracking.Infra.EctoKnownDeviceRepository
  alias KachingkoApi.LoginTracking.Application.ValueObjects.Authentication

  alias KachingkoApi.LoginTracking.Application.Commands.LoginDevice, as: LoginDeviceCommand

  def track_login(%Authentication{} = params) do
    with {:ok, command} <- LoginDeviceCommand.from_guardian_opts(params),
         {:ok, entity} <- LoginDevice.new(command, params.user_id) do
      user_logins_attrs = %{
        user_id: entity.user_id,
        signed_in_at: DateTime.utc_now(),
        ip_address: params.ip_address,
        token_expires_at: params.token_expires_at,
        token_jti: params.token_jti,
        fingerprint: entity.fingerprint,
        session_id: params.session_id,
        signed_out_at: nil
      }

      EctoUserLoginRepository.create(user_logins_attrs)
      EctoKnownDeviceRepository.insert(entity)

      # notify login

      if LoginDevice.is_device_unknown?(entity) do
        # notify email new device
      end
    end
  end

  defp upsert_login_device() do
  end
end
