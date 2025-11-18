defmodule KachingkoApi.Authentication do
  @moduledoc """
  Public API for the Authentication bounded context.

  This module provides a clean facade for all authentication operations,
  hiding the internal complexity of commands, handlers, and repositories
  from other parts of the application.
  """

  alias KachingkoApi.Authentication.Domain.Entities.{User, Session}
  alias KachingkoApi.Shared.Result
  alias KachingkoApi.Authentication.Domain.Services.AuthenticationService

  alias KachingkoApi.Authentication.Application.Commands.{
    RegisterUser,
    LoginUser,
    LogoutUser,
    ValidateSession
  }

  alias KachingkoApi.Authentication.Application.Handlers.{
    RegisterUserHandler,
    LoginUserHandler,
    LogoutUserHandler,
    ValidateSessionHandler
  }

  alias KachingkoApi.Authentication.Infra.{
    EctoUserRepository,
    GuardianSessionRepository
  }

  defp default_deps do
    %{
      user_repository: EctoUserRepository,
      session_repository: GuardianSessionRepository
    }
  end

  @type user :: User.t()
  @type session :: Session.t()
  @type auth_result :: Result.t({user(), session(), String.t()})
  @type validation_result :: Result.t({user(), session()})
  @type audience :: String.t()

  @doc """
  Register a new user with email and password.

  ## Parameters
  - email: User's email address
  - password: User's password (will be hashed)
  - audience: Token audience ("web" or "mobile"), defaults to "web"
  - deps: Dependency injection map (optional, for testing)

  ## Returns
  {:ok, %{user: user, session: session, token: token}} | {:error, error}

  ## Examples
      iex> Authentication.register("user@example.com", "password123")
        {:ok, %{user: %RegisteredUser{}, session: %Session{}, token: "jwt_token..."}}

      iex> Authentication.register("user@example.com", "password123", "mobile")
      {:ok, %{user: %User{}, session: %Session{aud: "mobile"}, token: "jwt_token..."}}

      iex> Authentication.register("invalid-email", "password123")
      {:error, %ValidationError{message: "Invalid email format"}}
  """

  @spec register(String.t(), String.t(), audience(), map()) :: auth_result()
  def register(email, password, _audience \\ "web", deps \\ nil) do
    params = %{email: email, password: password}
    deps = deps || default_deps()

    case RegisterUser.new(params) do
      {:ok, command} ->
        RegisterUserHandler.handle(command, deps)

      {:error, %Ecto.Changeset{} = error} ->
        {:error, error}

      error ->
        IO.inspect(error)
    end
  end

  @doc """
  Authenticate user with email and password, creating a new session.

  ## Parameters
  - email: User's email address
  - password: User's password
  - audience: Token audience ("web" or "mobile"), defaults to "web"
  - deps: Dependency injection map (optional, for testing)

  ## Returns
  {:ok, %{user: user, session: session, token: token}} | {:error, error}

  ## Examples
      iex> Authentication.login("user@example.com", "password123")
      {:ok, %{user: %AuthenticatedUser{}, session: %Session{}, token: "jwt_token..."}}

      iex> Authentication.login("user@example.com", "wrong_password")
      {:error, %AuthenticationError{message: "Invalid credentials"}}

      iex> Authentication.login("", "wrong_password")
      {:error, %Ecto.Changeset{invalid? true, ...}}
  """
  @spec login(String.t(), String.t(), audience(), map(), map()) :: auth_result()
  def login(email, password, _audience \\ "web", tracking_params \\ %{}, deps \\ nil) do
    deps = deps || default_deps()

    case LoginUser.new(%{email: email, password: password}) do
      {:ok, command} ->
        LoginUserHandler.handle(command, tracking_params, deps)

      {:error, %Ecto.Changeset{} = error} ->
        {:error, error}

      error ->
        error
    end
  end

  @spec verify_2fa_token(map(), map()) :: term()
  def verify_2fa_token(params, deps \\ nil) do
    deps = deps || default_deps()

    AuthenticationService.verify_2fa_token(
      params["pending_token"],
      params["code"],
      params["device"],
      deps
    )
  end

  @doc """
  Validate a session token and return user and session information.

  ## Parameters
  - token: JWT token to validate
  - deps: Dependency injection map (optional, for testing)

  ## Returns
  {:ok, %{user: user, session: session}} | {:error, error}

  ## Examples
      iex> Authentication.validate_session("valid_jwt_token")
      {:ok, %{user: %RegisteredUser{}, session: %Session{}}}

      iex> Authentication.validate_session("invalid_token")
      {:error, %AuthenticationError{message: "Invalid session"}}
  """
  @spec validate_session(String.t(), map()) :: validation_result()
  def validate_session(token, deps \\ nil) do
    deps = deps || default_deps()

    %{token: token}
    |> ValidateSession.new()
    |> ValidateSessionHandler.handle(deps)
  end

  @doc """
  Logout user by revoking the session token.

  ## Parameters
  - token: JWT token to revoke
  - deps: Dependency injection map (optional, for testing)

  ## Returns
  {:ok, :ok} | {:error, error}

  ## Examples
      iex> Authentication.logout("valid_jwt_token")
      {:ok, :ok}

      iex> Authentication.logout("invalid_token")
      {:ok, :ok}  # Idempotent operation
  """
  @spec logout(String.t(), map()) :: Result.t(:ok)
  def logout(token, deps \\ nil) do
    deps = deps || default_deps()

    %{token: token}
    |> LogoutUser.new()
    |> LogoutUserHandler.handle(deps)
  end

  @doc """
  Logout all sessions for a user.

  ## Parameters
  - user_id: ID of the user whose sessions should be revoked
  - deps: Dependency injection map (optional, for testing)

  ## Returns
  {:ok, :ok} | {:error, error}

  ## Examples
      iex> Authentication.logout_all("user-123")
      {:ok, :ok}
  """
  @spec logout_all(String.t(), map()) :: Result.t(:ok)
  def logout_all(user_id, deps \\ nil) do
    deps = deps || default_deps()
    deps.session_repository.revoke_all_user_tokens(user_id)
  end

  @doc """
  Get all active sessions for a user.

  ## Parameters
  - user_id: ID of the user
  - deps: Dependency injection map (optional, for testing)

  ## Returns
  {:ok, [session]} | {:error, error}

  ## Examples
      iex> Authentication.get_user_sessions("user-123")
      {:ok, [%Session{aud: "web"}, %Session{aud: "mobile"}]}
  """

  @spec get_user_sessions(String.t(), map()) :: Result.t(list(session()))
  def get_user_sessions(user_id, deps \\ nil) do
    deps = deps || default_deps()
    deps.session_repository.get_user_sessions(user_id)
  end

  @doc """
  Check if an email already exists in the system.

  ## Parameters
  - email: Email address to check
  - deps: Dependency injection map (optional, for testing)

  ## Returns
  boolean()

  ## Examples
      iex> Authentication.email_exists?("existing@example.com")
      true

      iex> Authentication.email_exists?("new@example.com")
      false
  """
  @spec email_exists?(String.t(), map()) :: boolean()
  def email_exists?(email, deps \\ nil) do
    deps = deps || default_deps()
    deps.user_repository.email_exists?(email)
  end

  @doc """
  Get user by ID.

  ## Parameters
  - user_id: ID of the user
  - deps: Dependency injection map (optional, for testing)

  ## Returns
  {:ok, user} | {:error, error}

  ## Examples
      iex> Authentication.get_user("user-123")
      {:ok, %User{id: "user-123", email: %Email{value: "user@example.com"}}}

      iex> Authentication.get_user("nonexistent")
      {:error, %NotFoundError{message: "User not found"}}
  """
  @spec get_user(String.t(), map()) :: Result.t(user())
  def get_user(user_id, deps \\ nil) do
    deps = deps || default_deps()
    deps.user_repository.get_by_id(user_id)
  end

  @doc """
  Get user by email address.

  ## Parameters
  - email: Email address
  - deps: Dependency injection map (optional, for testing)

  ## Returns
  {:ok, user} | {:error, error}

  ## Examples
      iex> Authentication.get_user_by_email("user@example.com")
      {:ok, %User{email: %Email{value: "user@example.com"}}}

      iex> Authentication.get_user_by_email("nonexistent@example.com")
      {:error, %NotFoundError{message: "User not found"}}
  """
  @spec get_user_by_email(String.t(), map()) :: Result.t(user())
  def get_user_by_email(email, deps \\ nil) do
    deps = deps || default_deps()
    deps.user_repository.get_by_email(email)
  end

  @doc """
  Clean up expired tokens from the database.
  This is typically called by a background job.

  ## Parameters
  - deps: Dependency injection map (optional, for testing)

  ## Returns
  {:ok, count} | {:error, error}

  ## Examples
      iex> Authentication.cleanup_expired_tokens()
      {:ok, 42}  # 42 expired tokens were removed
  """
  @spec cleanup_expired_tokens(map()) :: Result.t(integer())
  def cleanup_expired_tokens(deps \\ nil) do
    deps = deps || default_deps()
    deps.session_repository.cleanup_expired_tokens()
  end
end
