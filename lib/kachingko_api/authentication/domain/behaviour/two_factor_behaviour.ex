defmodule KachingkoApi.Authentication.Domain.Behaviour.TwoFactorBehaviour do
  @moduledoc """
  Behaviour for implementing different 2FA methods.
  Makes it easy to add email, SMS, or other 2FA methods.
  """

  @doc """
  Generates a new secret for the 2FA method.
  """
  @callback generate_secret() :: String.t()

  @doc """
  Generates a code for the user (for methods that send codes like email/SMS).
  """
  @callback generate_code(map()) :: {:ok, String.t()} | {:error, term()}

  @doc """
  Verifies a code against the user's 2FA setup.
  """
  @callback verify_code(user :: any(), code :: String.t()) :: boolean()

  @doc """
  Gets provisioning data needed for setup (e.g., QR code data for TOTP).
  """
  @callback get_provisioning_data(user :: any(), secret :: String.t()) :: map()
end
