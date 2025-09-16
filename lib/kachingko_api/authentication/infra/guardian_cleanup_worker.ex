defmodule KachingkoApi.Authentication.Infra.GuardianCleanupWorker do
  use GenServer
  alias KachingkoApi.Authentication.Domain.Services.SessionCleanupService
  alias KachingkoApi.Authentication.Infrastructure.Repositories.GuardianSessionRepository

  require Logger

  # Run every 6 hours
  @cleanup_interval :timer.hours(6)

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    schedule_cleanup()
    {:ok, %{}}
  end

  @impl true
  def handle_info(:cleanup, state) do
    deps = %{session_repository: GuardianSessionRepository}

    case SessionCleanupService.cleanup_expired_sessions(deps) do
      {:ok, count} ->
        Logger.info("Guardian: Cleaned up #{count} expired tokens")

      {:error, error} ->
        Logger.error("Guardian: Failed to cleanup tokens: #{inspect(error)}")
    end

    schedule_cleanup()
    {:noreply, state}
  end

  defp schedule_cleanup do
    Process.send_after(self(), :cleanup, @cleanup_interval)
  end
end
