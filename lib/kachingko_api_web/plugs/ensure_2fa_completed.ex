defmodule KachingkoApiWeb.Plugs.Ensure2FACompleted do
  @moduledoc """
  Ensures that the token is not a 2FA pending token.
  Allows access only with full access tokens.
  """

  import Plug.Conn
  require Logger

  def init(opts), do: opts

  def call(conn, _opts) do
    with claims <- Guardian.Plug.current_claims(conn),
         :ok <- verify_not_2fa_pending(claims) do
      conn
    else
      :error ->
        conn
        |> put_status(:forbidden)
        |> Phoenix.Controller.json(%{error: "2FA verification required"})
        |> halt()

      _ ->
        conn
        |> put_status(:forbidden)
        |> Phoenix.Controller.json(%{error: "2FA verification required"})
        |> halt()
    end
  end

  defp verify_not_2fa_pending(claims) do
    case claims do
      %{"2fa_required" => true} -> :error
      %{"typ" => "2fa_pending"} -> :error
      %{"typ" => "access"} -> :ok
      _ -> :error
    end
  end
end
