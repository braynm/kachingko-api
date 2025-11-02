defmodule KachingkoApi.LoginTracking.Infra.EctoKnownDeviceRepository do
  @behaviour KachingkoApi.LoginTracking.Domain.Repositories.KnownDeviceRepository

  alias KachingkoApi.Repo
  alias KachingkoApi.Shared.Errors
  alias KachingkoApi.Shared.Result
  alias KachingkoApi.LoginTracking.Infra.Schemas.KnownDeviceSchema
  alias KachingkoApi.LoginTracking.Application.Entities.LoginDevice

  @impl true
  def insert(%LoginDevice{} = entity) do
    KnownDeviceSchema.changeset(entity)
    |> Repo.insert(
      on_conflict: {:replace, [:device_fingerprint, :device_info, :updated_at]},
      conflict_target: [:user_id, :device_fingerprint],
      returning: true
    )
    |> case do
      {:ok, schema} -> to_entity(schema)
      {:error, changeset} -> Result.error(changeset_to_error(changeset))
    end
  end

  defp to_entity(schema) do
    LoginDevice.from_schema(schema) |> IO.inspect()
  end

  defp changeset_to_error(%Ecto.Changeset{errors: errors}) do
    {_field, {message, _}} = List.first(errors)
    %Errors.ValidationError{message: message}
  end
end
