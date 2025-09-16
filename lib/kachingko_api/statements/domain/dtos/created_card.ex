defmodule KachingkoApi.Statements.Domain.Dtos.CreatedNewCard do
  alias KachingkoApi.Shared.Result
  alias KachingkoApi.Shared.BankFormatter

  @type t :: %__MODULE__{
          id: String.t(),
          bank: String.t(),
          name: String.t()
        }

  defstruct [:id, :bank, :name]

  def new(item) when is_map(item) do
    Result.ok(%__MODULE__{
      id: item.id,
      bank: BankFormatter.format(item.bank),
      name: item.name
    })
  end
end
