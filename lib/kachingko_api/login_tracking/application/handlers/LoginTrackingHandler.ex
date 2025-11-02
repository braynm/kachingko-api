defmodule KachingkoApi.LoginTracking.Application.Handlers.LoginTrackingHandler do
  alias KachingkoApi.LoginTracking.Application.Commands.LoginDevice, as: LoginDeviceCommand
  alias KachingkoApi.LoginTracking.Infra.EctoKnownDeviceRepository
  alias KachingkoApi.LoginTracking.Application.Entities.LoginDevice
  alias KachingkoApi.LoginTracking.Application.ValueObjects.IPAddress
  alias KachingkoApi.LoginTracking.Application.Entities.LoginDevice

  def handle(%LoginDeviceCommand{} = command, user_id, deps \\ nil) when is_integer(user_id) do
    deps = deps || default_deps()

    with {:ok, ip_address} <- IPAddress.new(command.ip_address),
         command <- command_with_valid_ip_address(command, ip_address),
         {:ok, entity} <- LoginDevice.new(command, user_id) do
      deps.device_repository.insert(entity)
    end
  end

  defp command_with_valid_ip_address(command, %IPAddress{} = ip) do
    # modify ip address
    %{command | ip_address: ip.value}
  end

  defp default_deps() do
    %{
      device_repository: EctoKnownDeviceRepository
    }
  end
end
