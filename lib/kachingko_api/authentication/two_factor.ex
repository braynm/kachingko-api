defmodule KachingkoApi.Authentication.TwoFactor do
  @moduledoc """
  Public API for the 2FA bounded context.
  """

  alias KachingkoApi.Authentication.Domain.Entities.User
  alias KachingkoApi.Authentication.Domain.Services.TwoFactorService

  defdelegate initiate_setup(user), to: TwoFactorService
  defdelegate complete_setup(user, secret, code), to: TwoFactorService
  defdelegate disable(user), to: TwoFactorService
  defdelegate verify_code(user, code), to: TwoFactorService
  # defdelegate send_code(user), to: TwoFactorService

  @doc """
  Checks if user has 2FA enabled.
  """
  def enabled?(%User{two_factor_enabled: enabled}), do: enabled
  def enabled?(_), do: false
end
