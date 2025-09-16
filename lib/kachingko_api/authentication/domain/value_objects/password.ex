defmodule KachingkoApi.Authentication.Domain.ValueObjects.Password do
  alias KachingkoApi.Shared.Result
  alias KachingkoApi.Shared.Errors

  @type t :: %__MODULE__{value: String.t()}
  defstruct [:value]

  @min_length 4

  def new(password) when is_binary(password) do
    if String.length(password) >= @min_length do
      Result.ok(%__MODULE__{value: password})
    else
      Result.error(%Errors.ValidationError{
        message: "Password must be at least #{@min_length}"
      })
    end
  end

  def new(_),
    do:
      Result.error(%Errors.ValidationError{
        message: "Password must be a string"
      })

  def to_string(%__MODULE__{value: value}), do: value

  def hash(%__MODULE__{value: password}), do: Bcrypt.hash_pwd_salt(password)

  def verify(password, hash) when is_binary(password) and is_binary(hash) do
    Bcrypt.verify_pass(password, hash)
  end
end
