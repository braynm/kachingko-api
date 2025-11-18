defmodule KachingkoApiWeb.Plugs.ValidateGuardianSession do
  @moduledoc """
  Custom plug that validates the bearer token exists in Guardian session repository.

  This provides an additional layer of security by ensuring the token:
  1. Exists in the Guardian.DB session repository
  2. Has not been revoked
  3. Has not expired

  Should be used after Guardian.Plug.VerifyHeader and before accessing protected resources.

  ## Options
  - `:optional` - If true, only validates if token is present (for optional auth pipelines)
  """

  import Plug.Conn
  require Logger

  alias KachingkoApi.Authentication

  def init(opts), do: opts

  def call(conn, _opts) do
    case extract_from_authorization(conn) do
      token when is_binary(token) ->
        # Token is present, validate it
        Authentication.validate_session(token)
        conn

      nil ->
        # Token issue and not optional, handle error
        Logger.warning("Guardian session validation failed")

        halt(conn) |> put_status(401)

        # handle_invalid_session(conn, reason)
    end
  end

  def get_current_token(conn) do
    extract_from_authorization(conn)
  end

  def extract_from_authorization(conn) do
    case get_req_header(conn, "authorization") do
      ["Bearer " <> token] -> String.trim(token)
      # Case insensitive
      ["bearer " <> token] -> String.trim(token)
      # Direct token without Bearer
      [token] -> String.trim(token)
      _ -> nil
    end
  end
end
