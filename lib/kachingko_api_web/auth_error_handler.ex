defmodule KachingkoApiWeb.AuthErrorHandler do
  @moduledoc """
  Handles authentication errors for Guardian
  """
  import Plug.Conn

  @doc """
  Handle Guardian authentication errors
  """
  def auth_error(conn, {type, _reason}, _opts) do
    body = %{
      error: %{
        code: type,
        message: message_for_type(type)
      }
    }

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(status_for_type(type), Jason.encode!(body))
  end

  defp status_for_type(:invalid_token), do: 401
  defp status_for_type(:unauthenticated), do: 401
  defp status_for_type(:no_resource_found), do: 401
  defp status_for_type(:already_authenticated), do: 400
  defp status_for_type(:not_authenticated), do: 401
  defp status_for_type(_), do: 401

  defp message_for_type(:invalid_token), do: "Invalid or expired token"
  defp message_for_type(:unauthenticated), do: "Authentication required"
  defp message_for_type(:no_resource_found), do: "User not found"
  defp message_for_type(:already_authenticated), do: "Already authenticated"
  defp message_for_type(:not_authenticated), do: "Authentication required"
  defp message_for_type(type), do: "Authentication error: #{type}"
end
