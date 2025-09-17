defmodule KachingkoApi.Statements.Domain.Services.DuplicateChecker do
  @moduledoc """
  Service for checking duplicate statement uploads
  """

  alias KachingkoApi.Statements.Infra.EctoCardStatementRepository
  alias KachingkoApi.Statements.Domain.ValueObjects.FileChecksum

  def check_duplicate(user_id, %FileChecksum{} = checksum) do
    checksum_string = FileChecksum.to_string(checksum)

    case EctoCardStatementRepository.find_by_checksum(user_id, checksum_string) do
      nil ->
        :ok

      existing_statement ->
        {:error, {:duplicate_statement, card_id: existing_statement.id}}
    end
  end
end
