defmodule KachingkoApi.Authentication.Application.Handlers.RegisterUserHandler do
  alias KachingkoApi.Shared.{Result, Errors}
  alias KachingkoApi.Authentication.Application.Commands.RegisterUser
  alias KachingkoApi.Authentication.Domain.Repositories.UserRepository
  alias KachingkoApi.Authentication.Domain.Services.AuthenticationService
  alias KachingkoApi.Authentication.Domain.Services.UserRegistrationService
  alias KachingkoApi.Authentication.Domain.Dtos.RegisteredUser

  alias KachingkoApi.Repo

  @type deps :: %{
          user_repository: UserRepository.t(),
          session_repository: SessionRepository.t(),
          transaction_fn: function() | nil
        }

  def handle(%RegisterUser{} = command, deps) do
    transaction_fn = deps[:transaction_fn] || (&default_transaction/1)

    result =
      transaction_fn.(fn ->
        with {:ok, saved_user} <-
               UserRegistrationService.register_user(command.email, command.password, deps),
             {:ok, {session, token}} <- AuthenticationService.create_session(saved_user, deps) do
          Result.ok(%{
            user: RegisteredUser.new(saved_user),
            session: session,
            token: token
          })
        else
          true ->
            Result.error(%Errors.ValidationError{
              message: "Email already exists"
            })

          error ->
            error
        end
      end)

    # unwrap since `Repo.transaction` wrap it into ok/error tuple
    case result do
      {:ok, result} -> result
      {:error, _} = error -> error
    end
  end

  defp default_transaction(fun) do
    Repo.transaction(fun)
  end
end
