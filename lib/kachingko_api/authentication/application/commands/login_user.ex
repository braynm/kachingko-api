defmodule KachingkoApi.Authentication.Application.Commands.LoginUser do
  alias KachingkoApi.Utils.ValidatorFormatter

  @type t :: %__MODULE__{
          email: String.t(),
          password: String.t()
        }

  defstruct [:email, :password]

  defmodule Validator do
    use Ecto.Schema
    import Ecto.Changeset

    @derive {Jason.Encoder, only: [:email, :password]}

    @primary_key false
    embedded_schema do
      field :email, :string
      field :password, :string
    end

    def changeset(params) do
      %__MODULE__{}
      |> cast(params, [:email, :password])
      |> validate_required([:email], message: "Email can't be blank")
      |> validate_required([:password], message: "Password can't be blank")
      |> validate_length(:email, min: 3, max: 255)
      |> validate_length(:password, min: 3, message: "Password should be at least 3 character(s)")
      |> validate_format(:email, ~r/\S+@\S+\.\S+/, message: "Email must be a valid email")
    end
  end

  def new(params) do
    case Validator.changeset(params) do
      %Ecto.Changeset{valid?: true} = changeset ->
        validated_data = Ecto.Changeset.apply_changes(changeset)

        command = %__MODULE__{
          email: validated_data.email,
          password: validated_data.password
        }

        {:ok, command}

      %Ecto.Changeset{valid?: false} = changeset ->
        {:error, ValidatorFormatter.first_errors_by_field(changeset)}
    end
  end
end
