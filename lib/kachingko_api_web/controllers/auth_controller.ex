defmodule KachingkoApiWeb.AuthController do
  use KachingkoApiWeb, :controller

  alias KachingkoApi.Authentication
  alias KachingkoApiWeb.Guardian

  def register(conn, params) do
    audience = Map.get(params, "audience", "web")

    case Authentication.register(params["email"], params["password"], audience) do
      {:ok, %{user: user, session: _session, token: token}} ->
        user =
          user
          |> Map.from_struct()

        conn
        |> put_status(:created)
        |> json(%{success: true, data: %{user: user, token: token}})

      {:error, %KachingkoApi.Shared.Errors.ValidationError{message: message}} ->
        conn
        |> put_status(400)
        |> json(%{success: false, error: message})

      {:error, error} ->
        conn
        |> put_status(400)
        |> json(%{success: false, error: error})
    end
  end

  def login(conn, params) do
    tracking_params = %{
      ip_address: conn.remote_ip,
      fingerprint: get_in(params, ["device", "fingerprint"]),
      screen_resolution: get_in(params, ["device", "metadata", "screenResolution"]),
      timezone: get_in(params, ["device", "metadata", "timezone"]),
      language: get_in(params, ["device", "metadata", "language"]),
      browserName: get_in(params, ["device", "metadata", "browserName"]),
      osName: get_in(params, ["device", "metadata", "osName"]),
      platform: get_in(params, ["device", "metadata", "platform"])
    }

    # case Authentication.login(auth_params, guardian_opts) do
    case Authentication.login(params["email"], params["password"], "web", tracking_params) do
      {:ok, %{user: user, session: {_, token}}} ->
        user =
          user
          |> Map.from_struct()
          |> IO.inspect()

        conn
        |> put_status(:created)
        |> json(%{success: true, data: %{user: user, token: token}})

      {:error, error} ->
        IO.inspect(error)

        conn
        |> put_status(400)
        |> json(%{
          error:
            cond do
              # we specify error to email only since this is the application for login
              is_struct(error) ->
                error
                |> Map.from_struct()
                |> Map.drop([:__exception__])
                |> Map.fetch!(:message)

              # Contains the whole object of validation of all errors from all fields
              true ->
                error
                |> Map.to_list()
                |> Enum.map(fn {_k, v} -> v end)
                |> List.first()
            end
        })
    end
  end

  def logout(conn, _params) do
    token = KachingkoApiWeb.Plugs.ValidateGuardianSession.get_current_token(conn)

    case Authentication.logout(token) do
      {:ok, :ok} ->
        conn
        |> put_status(:ok)
        |> json(%{message: "Successfully logged out", success: true})

      {:error, _error} ->
        conn
        |> put_status(400)
        |> json(%{error: "Something went wrong, Please try again later.", success: false})
    end
  end

  def logout_all(conn, _params) do
    user = Guardian.Plug.current_resource(conn)

    case Authentication.logout_all(user.id) do
      {:ok, :ok} ->
        json(conn, %{data: "Successfully logged out from all devices", success: true})

      {:error, error} ->
        conn
        |> put_status(:bad_request)
        |> json(%{error: error, success: false})
    end
  end

  def me(conn, _params) do
    user = Guardian.Plug.current_resource(conn)
    session = Guardian.Plug.current_claims(conn)

    conn
    |> put_status(:ok)
    |> json(%{
      user: %{user: user.email.value, created_at: user.created_at, updated_at: user.updated_at},
      session: session
    })
  end

  def sessions(conn, _params) do
    user = Guardian.Plug.current_resource(conn)

    case Authentication.get_user_sessions(user.id) do
      {:ok, sessions} ->
        conn
        |> put_status(:ok)
        |> render(:sessions, %{sessions: sessions})

      {:error, error} ->
        {:error, error}
    end
  end

  def refresh(conn, _params) do
    token = Guardian.Plug.current_token(conn)

    case Guardian.refresh(token) do
      {:ok, _old_token, {new_token, _new_claims}} ->
        case Authentication.validate_session(new_token) do
          {:ok, %{user: user, session: session}} ->
            conn
            |> put_status(:ok)
            |> render(:auth_success, %{user: user, session: session, token: new_token})

          {:error, error} ->
            {:error, error}
        end

      {:error, error} ->
        {:error, error}
    end
  end
end
