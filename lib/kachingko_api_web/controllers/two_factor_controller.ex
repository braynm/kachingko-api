defmodule KachingkoApiWeb.TwoFactorController do
  use KachingkoApiWeb, :controller
  alias KachingkoApiWeb.Guardian
  alias KachingkoApi.Authentication.TwoFactor
  alias KachingkoApi.Authentication.Domain.Entities.User

  def initiate(conn, _params) do
    token = extract_from_authorization(conn)

    with {:ok, claims} <- Guardian.decode_and_verify(token),
         {:ok, user} <- Guardian.resource_from_claims(claims),
         {:ok, provisioning_data} <- TwoFactor.initiate_setup(User.from_authenticated_user(user)) do
      json(conn, %{data: provisioning_data, success: true})
    else
      error ->
        IO.inspect("Error occured: #{inspect(error)}")

        conn
        |> put_status(401)
        |> json(%{error: "Something went wrong. Please try again later."})
    end
  end

  def complete_setup(conn, params) do
    code = params["code"]
    secret = params["secret"]
    token = extract_from_authorization(conn)

    with {:ok, claims} <- Guardian.decode_and_verify(token),
         {:ok, user} <- Guardian.resource_from_claims(claims),
         {:ok, _, backup_codes} <-
           TwoFactor.complete_setup(User.from_authenticated_user(user), secret, code) do
      json(conn, %{
        success: true,
        data: backup_codes
      })
    else
      {:error, :invalid_code} ->
        conn
        |> put_status(401)
        |> json(%{error: "Invalid Two-Factor code"})

      error ->
        IO.inspect("Error occured: #{inspect(error)}")

        conn
        |> put_status(401)
        |> json(%{error: "Something went wrong. Please try again later."})
    end
  end

  defp extract_from_authorization(conn) do
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
