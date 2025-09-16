defmodule KachingkoApi.Authentication.Domain.Dtos.RegisteredUser do
  alias KachingkoApi.Authentication.Domain.Entities.User

  @type t :: %__MODULE__{id: integer(), email: String.t(), signed_up_at: DateTime.t()}
  defstruct [:id, :email, :signed_up_at]

  def new(%User{} = user) do
    %__MODULE__{
      id: user.id,
      email: user.email,
      signed_up_at: user.created_at
    }
  end

  def to_string(%__MODULE__{email: value}), do: value
end
