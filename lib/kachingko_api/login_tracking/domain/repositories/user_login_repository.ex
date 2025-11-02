defmodule KachingkoApi.LoginTracking.Domain.Repositories.UserLoginRepository do
  alias KachingkoApi.Shared.Result

  @type t :: module()

  @callback create(map()) :: Result.t(:ok | :error, term())
  # @callback get_by_user_id(String.t()) :: Result.t(Session.t())
  # @callback get_by_session_id(String.t()) :: Result.t(:ok)
  # @callback get_by_token_jti(String.t()) :: Result.t(:ok)
  # @callback get_user_sessions(String.t()) :: Result.t(list(Session.t()))
  # @callback get_recent_logins(String.t()) :: Result.t(list(Session.t()))
end
