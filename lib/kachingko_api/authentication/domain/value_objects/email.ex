defmodule KachingkoApi.Authentication.Domain.ValueObjects.Email do
  alias KachingkoApi.Shared.Result
  alias KachingkoApi.Shared.Errors

  @type t :: %__MODULE__{value: String.t()}
  defstruct [:value]

  @email_regex ~r/^[^\s]+@[^\s]+\.[^\s]+$/

  def new(email) when is_binary(email) do
    email =
      email
      |> String.trim()
      |> String.downcase()

    if Regex.match?(@email_regex, email) do
      Result.ok(%__MODULE__{value: email})
    else
      Result.error(%Errors.ValidationError{
        message: "Invalid email format"
      })
    end
  end

  def new(_) do
    Result.error(%Errors.ValidationError{
      message: "Email must be a string"
    })
  end

  def to_string(%__MODULE__{value: value}), do: value
end
