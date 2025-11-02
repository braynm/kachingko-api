defmodule KachingkoApi.LoginTracking.Infra.EctoUserLoginRepository do
  alias KachingkoApi.LoginTracking.Infra.Schemas.UserLoginschema
  alias KachingkoApi.Utils.ValidatorFormatter
  alias KachingkoApi.Shared.Result
  alias KachingkoApi.Repo

  @behaviour KachingkoApi.LoginTracking.Domain.Repositories.UserLoginRepository

  @impl true
  def create(params) do
    UserLoginschema.changeset(params)
    |> Repo.insert()
    |> case do
      {:ok, schema} -> Result.ok(schema)
      {:error, changeset} -> Result.error(changeset_to_error(changeset))
    end
  end

  defp changeset_to_error(%Ecto.Changeset{valid?: false} = changeset) do
    ValidatorFormatter.first_errors_by_field(changeset)
  end
end
