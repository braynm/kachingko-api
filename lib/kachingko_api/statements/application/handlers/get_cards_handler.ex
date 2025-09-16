defmodule KachingkoApi.Statements.Application.Handlers.GetCardsHandler do
  alias KachingkoApi.Shared.Result
  alias KachingkoApi.Statements.Domain.Dtos.Card

  def handle(user_id, deps) do
    cond do
      is_nil(user_id) -> {:error, "User id is required"}
      true -> deps.repo.list_user_cards(user_id) |> to_dtos()
    end
  end

  defp to_dtos({:ok, items}) do
    cards =
      Enum.map(items, fn card ->
        {:ok, card} = Card.new(card)
        card
      end)
      |> Enum.sort_by(fn card -> {card.bank, card.name} end)

    Result.ok(cards)
  end
end
