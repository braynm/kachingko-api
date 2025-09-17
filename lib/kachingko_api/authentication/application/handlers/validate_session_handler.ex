defmodule KachingkoApi.Authentication.Application.Handlers.ValidateSessionHandler do
  alias KachingkoApi.Authentication.Application.Commands.ValidateSession
  alias KachingkoApi.Authentication.Domain.Services.AuthenticationService
  alias KachingkoApi.Authentication.Domain.Repositories.UserRepository
  alias KachingkoApi.Shared.Result

  @type deps :: %{
          user_repository: UserRepository.t(),
          session_repository: SessionRepository.t()
        }

  def handle(%ValidateSession{} = command, deps) do
    with {:ok, session} <- AuthenticationService.validate_session(command.token, deps),
         {:ok, user} <- deps.user_repository.get_by_id(session.user_id) do
      Result.ok(%{user: user, session: session})
    else
      error -> error
    end
  end
end
