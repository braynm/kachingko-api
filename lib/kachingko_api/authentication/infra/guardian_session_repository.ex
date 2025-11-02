defmodule KachingkoApi.Authentication.Infra.GuardianSessionRepository do
  @behaviour KachingkoApi.Authentication.Domain.Repositories.SessionRepository

  alias KachingkoApi.Authentication.Domain.Entities.Session
  alias KachingkoApi.Authentication.Infra.EctoUserRepository
  alias KachingkoApiWeb.Guardian, as: GuardianWeb
  alias KachingkoApi.Shared.{Result, Errors}
  alias KachingkoApi.Repo

  import Ecto.Query

  def create_token(%Session{} = session, login_tracking_params \\ %{}) do
    with {:ok, user} <- EctoUserRepository.get_by_id(session.user_id),
         {:ok, token, claims} <-
           GuardianWeb.encode_and_sign(
             user,
             %{},
             audience: session.aud,
             jti: session.jti,
             login_tracking: login_tracking_params
           ),
         updated_session <- update_session_from_claims(session, claims) do
      Result.ok({updated_session, token})
    else
      {:error, error} -> Result.error(error)
      error -> Result.error(error)
    end
  end

  def validate_token(token) when is_binary(token) do
    with {:ok, claims} <- GuardianWeb.decode_and_verify(token),
         {:ok, user} <- GuardianWeb.resource_from_claims(claims),
         {:ok, session} <- build_session_from_claims(claims, user) do
      Result.ok(session)
    else
      {:error, :token_not_found} ->
        Result.error(%Errors.AuthenticationError{message: "Invalid session"})

      {:error, :token_expired} ->
        Result.error(%Errors.AuthenticationError{message: "Session expired"})

      {:error, _reason} ->
        Result.error(%Errors.AuthenticationError{message: "Invalid session"})

      _error ->
        Result.error(%Errors.AuthenticationError{message: "Session validation failed"})
    end
  end

  def revoke_token(token) when is_binary(token) do
    case GuardianWeb.revoke(token) do
      {:ok, _claims} -> Result.ok(:ok)
      {:error, _reason} -> Result.ok(:ok)
    end
  end

  def revoke_all_user_tokens(user_id) when is_number(user_id) do
    revoke_all_user_tokens(Integer.to_string(user_id))
  end

  def revoke_all_user_tokens(user_id) when is_binary(user_id) do
    case EctoUserRepository.get_by_id(String.to_integer(user_id)) do
      {:ok, user} ->
        case Guardian.DB.revoke_all(%{"aud" => "web", "sub" => to_string(user.id)}) do
          {:ok, _} -> Result.ok(:ok)
          _ -> Result.error(:revoken_token_error)
        end

      error ->
        error
    end
  end

  def get_user_sessions(user_id) when is_binary(user_id) do
    tokens =
      from(t in Guardian.DB.Token,
        where: t.sub == ^user_id and is_nil(t.revoked_at),
        order_by: [desc: t.inserted_at]
      )
      |> Repo.all()
      |> Enum.map(&to_session/1)

    Result.ok(tokens)
  end

  def cleanup_expired_tokens do
    case Guardian.DB.Token.purge_expired_tokens() do
      {count, _} -> Result.ok(count)
      error -> Result.error(error)
    end
  end

  defp update_session_from_claims(session, claims) do
    %{session | jti: claims["jti"], expires_at: DateTime.from_unix!(claims["exp"])}
  end

  defp build_session_from_claims(claims, user) do
    Session.new(%{
      user_id: user.id,
      jti: claims["jti"],
      exp: claims["exp"],
      typ: claims["typ"],
      access: claims["access"],
      sub: claims["sub"]
    })

    # {:ok, Session.new(session)}
  end

  # defp to_session(token) when is_struct(token, Guardian.DB.Token) do
  defp to_session(%Guardian.DB.Token{} = token) do
    {:ok, session} =
      Session.new(%{
        id: token.jti,
        user_id: token.sub,
        jti: token.jti,
        aud: token.aud,
        expires_at: DateTime.from_unix!(token.exp),
        created_at: token.inserted_at,
        updated_at: token.updated_at
      })

    session
  end
end
