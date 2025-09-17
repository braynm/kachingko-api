defmodule KachingkoApi.Statements.Domain.Entities.Card do
  @moduledoc """
  Card domain entity
  """

  alias KachingkoApi.Shared.Result

  @type t :: %__MODULE__{
          id: String.t() | nil,
          user_id: String.t(),
          bank: String.t(),
          name: String.t()
        }

  defstruct [:id, :user_id, :bank, :name]

  def new(params) do
    Result.ok(%__MODULE__{
      id: params.id,
      user_id: params.user_id,
      bank: params.bank,
      name: Regex.replace(~r/\d{4}(?!.*\d{4})/, params.name, "****")
    })
  end
end
