defmodule KachingkoApi.LoginTracking.Domain.Repositories.KnownDeviceRepository do
  alias KachingkoApi.Authentication.Domain.Entities.Session
  alias KachingkoApi.Shared.Result

  @type t :: module()
  @type user_id :: Ecto.UUID.t()

  @callback insert(Session.t()) :: Result.t(Session.t(), String.t())
end
