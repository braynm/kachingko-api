defmodule KachingkoApi.Authentication.Domain.Services.AuthenticationService do
  alias KachingkoApi.Authentication.Domain.Entities.User
  alias KachingkoApi.Authentication.Domain.Entities.Session
  alias KachingkoApi.Authentication.Domain.Repositories.UserRepository
  alias KachingkoApi.Authentication.Domain.Repositories.SessionRepository
  alias KachingkoApi.Shared.Result
  alias KachingkoApi.Shared.Errors

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

  def create_session(%User{} = user, audience \\ "web", deps) do
    session_attrs = %{user_id: user.id, aud: audience}

    with {:ok, session} <- create_session_entity(session_attrs, audience),
         {:ok, {saved_session, token}} <- deps.session_repository.create_token(session) do
      Result.ok({saved_session, token})
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
