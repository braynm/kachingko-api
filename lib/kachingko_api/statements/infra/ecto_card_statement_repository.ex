defmodule KachingkoApi.Statements.Infra.EctoCardStatementRepository do
  @behaviour KachingkoApi.Statements.Domain.CardStatementRepo

  import Ecto.Query
  alias KachingkoApi.Repo
  alias KachingkoApi.Shared.Result
  alias KachingkoApi.Utils.ValidatorFormatter
  alias KachingkoApi.Statements.Domain.Entities.CardStatement
  alias KachingkoApi.Statements.Infra.Schemas.CardStatementSchema

  @impl true
  def find_by_checksum(user_id, checksum) do
    query =
      from(q in CardStatementSchema,
        where:
          q.user_id == ^user_id and
            q.file_checksum == ^checksum
      )

    Repo.one(query)
  end

  @impl true
  def save_statement(%CardStatement{id: nil} = statement) do
    attrs = %{
      file_checksum: statement.file_checksum,
      filename: statement.filename,
      user_id: statement.user_id,
      card_id: statement.card_id
    }

    %CardStatementSchema{}
    |> CardStatementSchema.changeset(attrs)
    |> Repo.insert()
    |> case do
      # {:ok, schema} -> Result.ok(to_domain(schema))
      {:ok, schema} -> Result.ok(schema)
      {:error, changeset} -> Result.error(changeset_to_error(changeset))
    end
  end

  defp changeset_to_error(%Ecto.Changeset{valid?: false} = changeset) do
    ValidatorFormatter.first_errors_by_field(changeset)
  end
end
