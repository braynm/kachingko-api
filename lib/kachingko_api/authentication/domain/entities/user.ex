defmodule KachingkoApi.Authentication.Domain.Entities.User do
  alias KachingkoApi.Authentication.Domain.ValueObjects.Email
  alias KachingkoApi.Authentication.Domain.ValueObjects.Password
  alias KachingkoApi.Authentication.Domain.Dtos.AuthenticatedUser

  alias KachingkoApi.Shared.Result

  @type t :: %__MODULE__{
          id: String.t() | nil,
          email: String.t(),
          password_hash: String.t(),
          created_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil,
          two_factor_enabled: boolean(),
          two_factor_secret: String.t() | nil,
          two_factor_method: String.t(),
          two_factor_backup_codes: [String.t()] | nil
        }

  defstruct [
    :id,
    :email,
    :password_hash,
    :created_at,
    :updated_at,
    :two_factor_enabled,
    :two_factor_secret,
    :two_factor_method,
    :two_factor_backup_codes
  ]

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

  def two_factor_enabled?(%__MODULE__{two_factor_enabled: enabled}), do: enabled
  def two_factor_enabled?(_), do: false

  def from_authenticated_user(%AuthenticatedUser{} = user) do
    %__MODULE__{
      id: user.id,
      email: user.email
    }
  end

  def from_two_factor_binary(secret) do
    Base.encode32(secret)
  end

  def from_two_factor_encoded(secret_in_binary) do
    Base.decode32(secret_in_binary)
  end
end
