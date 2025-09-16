defmodule KachingkoApi.Repo do
  use Ecto.Repo,
    otp_app: :kachingko_api,
    adapter: Ecto.Adapters.Postgres
end
