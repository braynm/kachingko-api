defmodule KachingkoApi.Authentication.Application.Handlers.LogoutUserHandler do
  alias KachingkoApi.Authentication.Application.Commands.LogoutUser
  alias KachingkoApi.Authentication.Domain.Services.AuthenticationService

  @type deps :: %{
          session_repository: SessionRepository.t()
        }

  def handle(%LogoutUser{} = command, deps) do
    AuthenticationService.logout(command.token, deps)
  end
end
