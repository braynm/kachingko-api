defmodule KachingkoApi.Authentication.Domain.Services.UserRegistrationService do
  alias KachingkoApi.Authentication.Domain.Entities.User
  alias KachingkoApi.Shared.{Result, Errors}

  def register_user(email, password, deps) do
    with :ok <- check_email_availability(email, deps),
         {:ok, user} <- create_user(email, password) do
      save_user(user, deps)
    end
  end

  defp check_email_availability(email, deps) do
    if deps.user_repository.email_exists?(email) do
      Result.error(%Errors.ValidationError{
        message: "Email already exists"
      })
    else
      :ok
    end
  end

  defp save_user(user, deps) do
    deps.user_repository.save(user)
  end

  defp create_user(email, password) do
    User.new(%{email: email, password: password})
  end
end
