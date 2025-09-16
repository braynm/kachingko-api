defmodule KachingkoApi.Authentication.Application.Commands.ValidateSession do
  @type t :: %__MODULE__{token: String.t()}

  defstruct [:token]

  def new(attrs) do
    %__MODULE__{token: attrs[:token]}
  end
end
