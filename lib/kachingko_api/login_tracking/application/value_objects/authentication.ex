defmodule KachingkoApi.LoginTracking.Application.ValueObjects.Authentication do
  @moduledoc """
  Value object representing the context of an authentication event.
  """

  @type t :: %__MODULE__{
          ip_address: String.t() | nil,
          fingerprint: String.t() | nil,
          screen_resolution: String.t(),
          timezone: String.t() | nil,
          browserName: String.t() | nil,
          osName: String.t() | nil,
          platform: String.t() | nil,
          language: String.t() | nil,
          token_jti: String.t() | nil,
          token_type: integer() | nil,
          token_expires_at: String.t() | nil,
          session_id: String.t() | nil,
          user_id: integer()
        }

  defstruct [
    :ip_address,
    :fingerprint,
    :screen_resolution,
    :timezone,
    :browserName,
    :osName,
    :platform,
    :language,
    :token_jti,
    :token_type,
    :token_expires_at,
    :session_id,
    :user_id
  ]

  def from_guardian_opts(options, claims) do
    %__MODULE__{
      ip_address: extract_ip_address(options),
      fingerprint: Map.get(options, :fingerprint),
      screen_resolution: Map.get(options, :screen_resolution),
      timezone: Map.get(options, :timezone),
      browserName: Map.get(options, :browserName),
      osName: Map.get(options, :osName),
      platform: Map.get(options, :platform),
      language: Map.get(options, :language),
      token_jti: Map.get(claims, "jti"),
      token_type: Map.get(claims, "typ"),
      token_expires_at: extract_expiry(claims),
      session_id: Map.get(options, :session_id) || Ecto.UUID.generate(),
      user_id: Map.get(claims, "sub") |> String.to_integer()
    }
  end

  defp extract_expiry(claims) do
    case Map.get(claims, "exp") do
      nil -> nil
      exp when is_integer(exp) -> DateTime.from_unix!(exp) |> DateTime.to_naive()
      _ -> nil
    end
  end

  defp extract_ip_address(options) do
    case Map.get(options, :ip_address) do
      nil -> nil
      ip when is_tuple(ip) -> ip |> :inet.ntoa() |> to_string()
      ip when is_binary(ip) -> ip
      _ -> nil
    end
  end
end
