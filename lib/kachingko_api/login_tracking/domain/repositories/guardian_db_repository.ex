defmodule KachingkoApi.LoginTracking.Domain.Repositories.GuardianDbRepository do
  alias KachingkoApi.Authentication.Domain.Entities.Session
  alias KachingkoApi.Shared.Result
  alias Guardian.DB.Token

  @type t :: module()
  @type user_id :: Ecto.UUID.t()

  @callback revoke_token_by_jti(Session.t()) :: Result.t(Session.t(), String.t())
  @callback revoke_all_tokens_by_user_id(Session.t()) :: Result.t(Session.t(), String.t())
  @callback revoke_all_other_tokens_except_session_id(Session.t()) ::
              Result.t(Session.t(), String.t())

  @callback find_token_by_session_id(Session.t()) :: Result.t(Session.t(), String.t())
end
