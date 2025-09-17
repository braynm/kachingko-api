defmodule KachingkoApi.Authentication.Domain.Entities.User do
  alias KachingkoApi.Authentication.Domain.ValueObjects.Email
  alias KachingkoApi.Authentication.Domain.ValueObjects.Password

  alias KachingkoApi.Shared.Result

  @type t :: %__MODULE__{
          id: String.t() | nil,
          email: String.t(),
          password_hash: String.t(),
          created_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil
        }

  defstruct [:id, :email, :password_hash, :created_at, :updated_at]

  @spec new(map()) :: {:ok, %__MODULE__{}} | {:error, term()}
  def new(attrs) do
    with {:ok, email} <- Email.new(attrs[:email]),
         {:ok, password} <- Password.new(attrs[:password]) do
      user = %__MODULE__{
        id: attrs[:id],
        email: email,
        password_hash: Password.hash(password),
        created_at: attrs[:created_at],
        updated_at: attrs[:updated_at]
      }

      Result.ok(user)
    else
      {:error, error} -> Result.error(error)
    end
  end

  def verify_password(hash, password) when is_binary(hash) do
    Password.verify(password, hash)
  end

  def email_string(%__MODULE__{email: email}) do
    Email.to_string(email)
  end
end
