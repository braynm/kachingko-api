defmodule KachingkoApi.Authentication.Domain.Services.SessionCleanupService do
  alias KachingkoApi.Authentication.Domain.Repositories.SessionRepository

  @type deps :: %{session_repository: SessionRepository.t()}

  def cleanup_expired_sessions(deps) do
    deps.session_repository.cleanup_expired_tokens()
  end
end
