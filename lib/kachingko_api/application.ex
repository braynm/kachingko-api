defmodule KachingkoApi.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      KachingkoApiWeb.Telemetry,
      KachingkoApi.Repo,
      {DNSCluster, query: Application.get_env(:kachingko_api, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: KachingkoApi.PubSub},
      # Start a worker by calling: KachingkoApi.Worker.start_link(arg)
      # {KachingkoApi.Worker, arg},
      # Start to serve requests, typically the last entry
      KachingkoApiWeb.Endpoint,
      {Guardian.DB.Sweeper, []},
      {KachingkoApi.Statements.PdfExtractor, []}
      # KachingkoApi.Vault
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: KachingkoApi.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    KachingkoApiWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
