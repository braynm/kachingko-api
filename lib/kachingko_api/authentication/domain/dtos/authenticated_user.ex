defmodule KachingkoApi.Authentication.Domain.Dtos.AuthenticatedUser do
  alias KachingkoApi.Authentication.Domain.Entities.User

  @type t :: %__MODULE__{id: integer(), email: String.t()}
  defstruct [:id, :email]

  def new(%User{} = user) do
    %__MODULE__{
      id: user.id,
      email: user.email
    }
  end

  def from_user(%User{} = user) do
    new(user)
  end

  def from_resource(%User{} = user) do
    new(user)
  end

  def to_string(%__MODULE__{email: value}), do: value
end
