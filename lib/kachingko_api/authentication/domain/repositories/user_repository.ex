defmodule KachingkoApi.Authentication.Domain.Repositories.UserRepository do
  alias KachingkoApi.Authentication.Domain.Entities.User
  alias KachingkoApi.Shared.Result

  @type t :: module()

  @callback save(User.t()) :: Result.t(User.t())
  @callback get_by_email(String.t()) :: Result.t(User.t())
  @callback get_by_id(integer()) :: Result.t(User.t())
  @callback email_exists?(String.t()) :: boolean()
end
