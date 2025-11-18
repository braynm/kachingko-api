defmodule KachingkoApi.Authentication.Domain.Repositories.UserRepository do
  alias KachingkoApi.Authentication.Domain.Entities.User
  alias KachingkoApi.Shared.Result

  @type t :: module()

  @callback save(User.t()) :: Result.t(User.t())
  @callback get_by_email(String.t()) :: Result.t(User.t())
  @callback get_by_id(integer()) :: Result.t(User.t())
  @callback email_exists?(String.t()) :: boolean()

  # Add 2FA methods
  @callback enable_two_factor(
              user :: User.t(),
              secret :: String.t(),
              backup_codes :: [String.t()]
            ) :: {:ok, User.t()} | {:error, Ecto.Changeset.t()}

  @callback disable_two_factor(user :: User.t()) :: {:ok, User.t()} | {:error, Ecto.Changeset.t()}

  @callback update_two_factor_settings(
              user :: User.t(),
              attrs :: map()
            ) :: {:ok, User.t()} | {:error, Ecto.Changeset.t()}
end
