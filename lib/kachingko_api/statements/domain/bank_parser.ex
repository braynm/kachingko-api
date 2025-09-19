defmodule KachingkoApi.Statements.Domain.BankParser do
  @moduledoc """
  Behaviour for bank-specific PDF parsers (e.g. BDO, RCBC, BPI)
  """

  alias KachingkoApi.Shared.Result

  @callback parse(binary()) :: Result.t([map()])
  @callback supported_bank() :: String.t()
end
