defmodule KachingkoApi.Statements.Application.Handlers.CreateNewCardHandler do
  alias KachingkoApi.Shared.Result
  alias KachingkoApi.Statements.Domain.Entities.Card
  alias KachingkoApi.Statements.Domain.Dtos.CreatedNewCard
  alias KachingkoApi.Statements.Application.Commands.CreateNewCard

  def handle(%CreateNewCard{} = command, deps) do
    params = %{
      id: nil,
      user_id: command.user_id,
      bank: command.bank,
      name: command.card_name
    }

    with {:ok, entity} <- Card.new(params),
         {:ok, record} <- deps.repo.create_card(entity),
         {:ok, created_new_card} <- CreatedNewCard.new(record) do
      Result.ok(created_new_card)
    end
  end
end
