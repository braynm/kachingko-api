defmodule KachingkoApi.Statements.Application.Commands.MonthSummarySpent do
  alias KachingkoApi.Shared.Result
  alias KachingkoApi.Utils.ValidatorFormatter

  import Ecto.Changeset

  @type t :: %__MODULE__{
          user_id: integer(),
          start_date: Date.t(),
          end_date: Date.t()
        }

  defstruct [:user_id, :end_date, :start_date]

  defmodule Validator do
    use Ecto.Schema
    import Ecto.Changeset

    @derive {Jason.Encoder, only: [:user_id, :start_date, :end_date]}

    @primary_key false
    embedded_schema do
      field :user_id, :integer
      field :start_date, :string
      field :end_date, :string
    end

    def changeset(params) do
      %__MODULE__{}
      |> cast(params, [:user_id, :start_date, :end_date])
      |> validate_required([:user_id, :start_date, :end_date])
      |> validate_and_convert_to_date(:start_date)
      |> validate_and_convert_to_date(:end_date)
      |> validate_range()
      |> format_errors()
    end

    defp validate_and_convert_to_date(%Ecto.Changeset{valid?: true} = changeset, field) do
      date_field = changeset.changes[field]

      case Date.from_iso8601(date_field) do
        {:ok, date} ->
          # make sure we pass date with utc to the database for accurate fetching
          # DateTimezone.from_mnl_to_utc(date)
          put_change(changeset, field, date)

        # put_change(changeset, field, date)

        {:error, _reason} ->
          add_error(changeset, field, "must be a valid date in YYYY-MM-DD format")
      end
    end

    defp validate_and_convert_to_date(changeset, _), do: changeset

    defp validate_range(%Ecto.Changeset{valid?: true, changes: changes} = changeset) do
      %{start_date: start_date, end_date: end_date} = changes

      if Date.compare(start_date, end_date) in [:lt, :eq] do
        changeset
      else
        add_error(changeset, :end_date, "must be on or after start date")
      end
    end

    defp validate_range(changeset), do: changeset

    defp format_errors(%Ecto.Changeset{valid?: false} = changeset) do
      field_labels = %{
        user_id: "User",
        start_date: "Start Date",
        end_date: "End Date"
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
          start_date: validated_data.start_date,
          end_date: validated_data.end_date
        }

        Result.ok(command)

      %Ecto.Changeset{valid?: false} = changeset ->
        Result.error(ValidatorFormatter.first_errors_by_field(changeset))
    end
  end
end
