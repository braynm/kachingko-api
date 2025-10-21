defmodule KachingkoApi.Statements.Domain.Dtos.UserTxn do
  alias KachingkoApi.Shared.Result
  alias KachingkoApi.Statements.Infra.Schemas.TransactionSchema
  alias KachingkoApi.Statements.Infra.Schemas.CardSchema
  alias KachingkoApi.Shared.BankFormatter

  @type t :: %__MODULE__{
          id: String.t(),
          user_id: String.t(),
          sale_date: String.t(),
          posted_date: String.t(),
          details: String.t(),
          amount: String.t(),
          card: String.t(),
          category: String.t()
        }

  defstruct [:id, :user_id, :sale_date, :posted_date, :details, :amount, :card, :category]

  def new(%{transaction: %TransactionSchema{} = transaction, card: %CardSchema{} = card}) do
    Result.ok(%__MODULE__{
      id: transaction.id,
      user_id: transaction.user_id,
      sale_date: to_iso8601(transaction.sale_date),
      posted_date: to_iso8601(transaction.posted_date),
      details: transaction.encrypted_details,
      amount: transaction.encrypted_amount,
      card: "#{BankFormatter.format(card.bank)} #{card.name}",
      category: transaction.category
    })
  end

  defp to_iso8601(%DateTime{} = datetime) do
    datetime
    |> DateTime.shift_zone!("Asia/Manila")
    |> DateTime.to_date()
    |> Date.to_iso8601()
  end
end
