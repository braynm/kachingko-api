defmodule KachingkoApi.Authentication.Application.Handlers.LoginUserHandler do
  alias KachingkoApi.Authentication.Application.Commands.LoginUser
  alias KachingkoApi.Authentication.Domain.Services.AuthenticationService
  alias KachingkoApi.Authentication.Domain.Dtos.AuthenticatedUser
  alias KachingkoApi.Shared.Result

  @type deps :: %{
          user_repository: UserRepository.t(),
          session_repository: SessionRepository.t()
        }

  def handle(%LoginUser{} = command, tracking_params, deps) do
    with {:ok, user} <- AuthenticationService.authenticate(command.email, command.password, deps),
         {:ok, session} <- AuthenticationService.create_session(user, tracking_params, deps) do
      Result.ok(%{
        user: AuthenticatedUser.new(user),
        # TODO: create session DTO
        session: session
      })
    else
      error -> error
    end
  end
end
