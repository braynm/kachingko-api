defmodule KachingkoApi.Authentication.Domain.Repositories.SessionRepository do
  alias KachingkoApi.Authentication.Domain.Entities.Session
  alias KachingkoApi.Shared.Result

  @type t :: module()

  @callback create_token(Session.t()) :: Result.t(Session.t(), String.t())
  @callback validate_token(String.t()) :: Result.t(Session.t())
  @callback revoke_token(String.t()) :: Result.t(:ok)
  @callback revoke_all_user_tokens(String.t()) :: Result.t(:ok)
  @callback get_user_sessions(String.t()) :: Result.t(list(Session.t()))
  @callback cleanup_expired_tokens() :: Result.t(integer())
end
