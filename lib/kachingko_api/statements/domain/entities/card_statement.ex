defmodule KachingkoApi.Statements.Domain.Entities.CardStatement do
  @moduledoc """
  Card Statement domain entity
  """

  alias KachingkoApi.Shared.Result

  @type t :: %__MODULE__{
          id: String.t() | nil,
          user_id: String.t(),
          card_id: String.t(),
          file_checksum: String.t(),
          filename: String.t(),
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  defstruct [:id, :card_id, :user_id, :filename, :file_checksum, :inserted_at, :updated_at]

  def new(params) do
    Result.ok(%__MODULE__{
      id: params["id"],
      user_id: params["user_id"],
      card_id: params["card_id"],
      filename: Regex.replace(~r/\d{4}(?!.*\d{4})/, params["filename"], "****"),
      file_checksum: params["file_checksum"],
      inserted_at: params["inserted_at"],
      updated_at: params["inserted_at"]
    })
  end
end
