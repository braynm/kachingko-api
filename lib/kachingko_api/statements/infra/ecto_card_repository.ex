defmodule KachingkoApi.Statements.Infra.EctoCardRepository do
  @behaviour KachingkoApi.Statements.Domain.CardRepo

  alias KachingkoApi.Repo
  alias KachingkoApi.Shared.Result
  alias KachingkoApi.Statements.Domain.Entities.Card
  alias KachingkoApi.Statements.Infra.Schemas.CardSchema
  alias KachingkoApi.Shared.Errors

  import Ecto.Query

  @impl true
  def create_card(%Card{id: nil} = entity) do
    attrs = %{
      name: entity.name,
      bank: String.downcase(entity.bank),
      user_id: entity.user_id
    }

    %CardSchema{}
    |> CardSchema.changeset(attrs)
    |> Repo.insert()
    |> case do
      {:ok, schema} -> Result.ok(schema)
      {:error, changeset} -> Result.error(changeset_to_error(changeset))
    end
  end

  @impl true
  def list_user_cards(user_id) when is_integer(user_id) do
    Result.ok(Repo.all(from q in CardSchema, where: q.user_id == ^user_id))
  end

  defp changeset_to_error(%Ecto.Changeset{errors: errors}) do
    {_field, {message, _}} = List.first(errors)
    %Errors.ValidationError{message: message}
  end
end
