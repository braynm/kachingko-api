defmodule KachingkoApi.Authentication.Application.Commands.RegisterUser do
  alias KachingkoApi.Shared.Result
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
      |> validate_required([:email, :password])
      |> validate_length(:email, min: 3, max: 255)
      |> validate_length(:password, min: 1)
      |> validate_format(:email, ~r/\S+@\S+\.\S+/, message: "must be a valid email")
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

        Result.ok(command)

      %Ecto.Changeset{valid?: false} = changeset ->
        Result.error(ValidatorFormatter.first_errors_by_field(changeset))
    end
  end
end
