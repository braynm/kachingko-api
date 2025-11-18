defmodule KachingkoApi.Authentication.Domain.Services.AuthenticationService do
  alias KachingkoApi.Authentication.Domain.Entities.User
  alias KachingkoApi.Authentication.Domain.Entities.Session
  alias KachingkoApi.Authentication.Domain.Repositories.UserRepository
  alias KachingkoApi.Authentication.Infra.EctoUserRepository
  alias KachingkoApi.Authentication.Domain.Repositories.SessionRepository
  alias KachingkoApi.Shared.Result
  alias KachingkoApi.Shared.Errors
  alias KachingkoApi.Authentication.Domain.Services.TwoFactorService
  alias KachingkoApi.Authentication.Domain.Dtos.AuthenticatedUser

  @type deps :: %{
          user_repository: UserRepository.t(),
          session_repository: SessionRepository.t()
        }

  def authenticate(email, password, deps) do
    with {:ok, user} <- deps.user_repository.get_by_email(email),
         true <- User.verify_password(user.password_hash, password) do
      Result.ok(user)
    else
      {:error, %Errors.NotFoundError{}} ->
        Result.error(%Errors.AuthenticationError{message: "Invalid credentials"})

      false ->
        Result.error(%Errors.AuthenticationError{message: "Invalid credentials"})

      error ->
        error
    end
  end

  def create_session(%User{} = user, audience \\ "web", login_tracking_params, deps) do
    session_attrs = %{user_id: user.id, aud: audience}

    if user.two_factor_enabled do
      {:ok, token, sess} = deps.session_repository.create_2fa_pending_token(user)
      Result.ok({sess, token})
    else
      with {:ok, session} <- create_session_entity(session_attrs, audience),
           {:ok, {saved_session, token}} <-
             deps.session_repository.create_token(session, login_tracking_params) do
        Result.ok({saved_session, token})
      else
        error -> error
      end
    end
  end

  # TODO: Fetching user duplicate calls on different parts. Optimize please!
  def verify_2fa_token(
        pending_token,
        two_factor_code,
        login_tracking_params,
        deps
      ) do
    with {:ok, user_id} <-
           deps.session_repository.verify_pending_token(pending_token),
         {:ok, user} <- EctoUserRepository.get_by_id(user_id),
         {:ok, :valid} <- TwoFactorService.verify_code(user, two_factor_code),
         {:ok, session} <- create_session_entity(%{user_id: user_id, aud: "web"}, "web"),
         {:ok, {saved_session, token}} <-
           deps.session_repository.create_token_from_user(session, user, login_tracking_params) do
      Result.ok(%{
        token: token,
        saved_session: saved_session,
        user: AuthenticatedUser.new(user)
      })
    else
      error -> error
    end
  end

  def logout(token, deps) do
    deps.session_repository.revoke_token(token)
  end

  def validate_session(token, deps) do
    deps.session_repository.validate_token(token)
  end

  def logout_all_sessions(user_id, deps) do
    deps.session_repository.revoke_all_user_tokens(user_id)
  end

  defp create_session_entity(attrs, "web") do
    Session.new_web(attrs)
  end
end
