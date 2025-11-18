defmodule KachingkoApiWeb.Guardian do
  use Guardian, otp_app: :kachingko_api

  alias KachingkoApi.LoginTracking
  alias KachingkoApi.Authentication.Infra.EctoUserRepository
  alias KachingkoApi.Authentication.Domain.Dtos.AuthenticatedUser
  alias KachingkoApi.Authentication.Domain.Services.TwoFactorService

  def subject_for_token(%{id: id}, _claims) do
    {:ok, to_string(id)}
  end

  def resource_from_claims(%{"sub" => id}) do
    case EctoUserRepository.get_by_id(String.to_integer(id)) do
      {:ok, user} -> {:ok, AuthenticatedUser.from_resource(user)}
      {:error, _} -> {:error, :resource_not_found}
    end
  end

  # def build_claims(claims, _user, opts) do
  #   # Add audience to claims for different client types
  #   audience = Keyword.get(opts, :audience, "web")
  #
  #   expires_at =
  #     DateTime.add(DateTime.utc_now(), get_token_ttl(audience), :second)
  #     |> IO.inspect(label: "EXPIRES ATTTTT")
  #
  #   claims =
  #     claims
  #     # |> IO.inspect()
  #     # |> Map.put("access", "2fa_pending")
  #     |> Map.put("aud", audience)
  #     |> Map.put("exp", DateTime.to_unix(expires_at))
  #
  #   {:ok, claims}
  # end

  # Consider making these configurable
  # defp get_token_ttl("mobile"), do: Application.get_env(:kachingko_api, :mobile_token_ttl)
  #
  # defp get_token_ttl("web"),
  #   do: Application.get_env(:kachingko_api, :web_token_ttl)

  # defp get_token_ttl(aud), do: raise("Env config for #{aud} is required!")

  def after_encode_and_sign(resource, claims, token, options) do
    with {:ok, _} <- Guardian.DB.after_encode_and_sign(resource, claims["typ"], claims, token) do
      tracking_opts = Keyword.get(options, :login_tracking)
      LoginTracking.track_login(tracking_opts, claims)
      {:ok, token}
    end
  end

  @doc """
  Creates a 2FA pending token with limited permissions.
  Expires in 5 minutes.
  """
  def encode_and_sign_2fa_pending(user, options \\ []) do
    claims = %{
      "typ" => "2fa_pending",
      "2fa_required" => true
    }

    # Short expiry for 2FA pending tokens
    token_options = Keyword.merge(options, ttl: {5, :minutes})

    encode_and_sign(user, claims, token_options)
  end

  @doc """
  Exchanges a 2FA pending token for a full access token after verification.
  """
  def exchange_2fa_token(pending_token, two_factor_code, login_tracking_params) do
    with {:ok, claims} <- decode_and_verify(pending_token),
         {:ok, user} <- resource_from_claims(claims),
         :ok <- verify_2fa_pending_token(claims),
         {:ok, _} <- TwoFactorService.verify_code(user, two_factor_code) do
      # Create full access token
      # GuardianWeb.encode_and_sign(
      #   user,
      #   %{},
      #   audience: claims.aud,
      #   jti: claims.jti,
      #   login_tracking: login_tracking_params
      # )

      encode_and_sign(
        user,
        %{"typ" => "ss"},
        login_tracking: LoginTracking.track_login(login_tracking_params, claims)
      )
    else
      {:error, :invalid_code} -> {:error, :invalid_2fa_code}
      error -> error
    end
  end

  def verify_2fa_pending_token(%{"typ" => "2fa_pending"}), do: :ok
  def verify_2fa_pending_token(_), do: {:error, :not_2fa_pending_token}

  def on_verify(claims, token, _options) do
    with {:ok, _} <- Guardian.DB.on_verify(claims, token) do
      {:ok, claims}
    end
  end

  def on_refresh({old_token, old_claims}, {new_token, new_claims}, _options) do
    with {:ok, _, _} <- Guardian.DB.on_refresh({old_token, old_claims}, {new_token, new_claims}) do
      {:ok, {old_token, old_claims}, {new_token, new_claims}}
    end
  end

  def on_revoke(claims, token, _options) do
    with {:ok, _} <- Guardian.DB.on_revoke(claims, token) do
      {:ok, claims}
    end
  end
end
