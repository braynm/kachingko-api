defmodule KachingkoApi.Authentication.Domain.Services.TOTP do
  @behaviour KachingkoApi.Authentication.Domain.Behaviour.TwoFactorBehaviour

  alias KachingkoApi.Authentication.Domain.Entities.User

  @impl true
  def generate_secret do
    NimbleTOTP.secret()
  end

  @impl true
  def generate_code(_user) do
    # TOTP doesn't send codes; users generate them in their app
    {:error, :not_applicable}
  end

  @impl true
  def verify_code(%User{two_factor_secret: secret}, code) when is_binary(secret) do
    {:ok, secret} = User.from_two_factor_encoded(secret)
    NimbleTOTP.valid?(secret, code)
  end

  def verify_code(_user, _code), do: false

  @impl true
  def get_provisioning_data(%User{email: email} = _user, secret) do
    app_name = Application.get_env(:kachingko_api, :kachingko_api, "KachingKoAPP")

    %{
      secret: secret,
      qr_code_url: NimbleTOTP.otpauth_uri("#{app_name}:#{email}", secret, issuer: app_name),
      method: "totp"
    }
  end
end
