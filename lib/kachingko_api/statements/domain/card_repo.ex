defmodule KachingkoApi.Statements.Domain.CardRepo do
  @type t :: module()
  @callback create_card(map()) :: {:ok, map()} | {:error, map()}
  @callback list_user_cards(integer()) :: {:ok, [map()]} | {:error, map()}
end
