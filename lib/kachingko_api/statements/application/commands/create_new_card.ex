defmodule KachingkoApi.Statements.Application.Commands.CreateNewCard do
  alias KachingkoApi.Shared.Result
  alias KachingkoApi.Utils.ValidatorFormatter

  import Ecto.Changeset

  @type t :: %__MODULE__{
          user_id: integer(),
          bank: String.t(),
          card_name: String.t()
        }

  defstruct [:user_id, :bank, :card_name]

  defmodule Validator do
    use Ecto.Schema
    import Ecto.Changeset

    @derive {Jason.Encoder, only: [:user_id, :bank, :card_name]}

    @primary_key false
    embedded_schema do
      field :user_id, :integer
      field :bank, :string
      field :card_name, :string
    end

    def changeset(params) do
      %__MODULE__{}
      |> cast(params, [:user_id, :bank, :card_name])
      |> validate_required([:user_id, :bank, :card_name])
      |> validate_bank()
      |> format_errors()
    end

    defp validate_bank(%Ecto.Changeset{valid?: true} = changeset) do
      case String.downcase(changeset.changes.bank) in ["eastwest", "rcbc"] do
        true ->
          changeset

        false ->
          add_error(changeset, :bank, "Unsupported bank. Please contact admin for support.")
      end
    end

    defp validate_bank(changeset), do: changeset

    defp format_errors(%Ecto.Changeset{valid?: false} = changeset) do
      field_labels = %{
        user_id: "User",
        bank: "Bank",
        card_name: "Card Name"
      }

      errors =
        Enum.map(changeset.errors, fn
          {field, {error_msg, opts}} ->
            label = if label = field_labels[field], do: label, else: field

            {field, {"#{label} #{error_msg}", opts}}
        end)

      %{changeset | errors: errors}
    end

    defp format_errors(changeset), do: changeset
  end

  def new(params) do
    case Validator.changeset(params) do
      %Ecto.Changeset{valid?: true} = changeset ->
        validated_data = Ecto.Changeset.apply_changes(changeset)

        command = %__MODULE__{
          user_id: validated_data.user_id,
          bank: validated_data.bank,
          card_name: validated_data.card_name
        }

        Result.ok(command)

      %Ecto.Changeset{valid?: false} = changeset ->
        Result.error(ValidatorFormatter.first_errors_by_field(changeset))
    end
  end
end
