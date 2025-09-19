defmodule KachingkoApi.Statements.Application.Commands.UploadStatementTransaction do
  alias KachingkoApi.Shared.Result
  alias KachingkoApi.Utils.ValidatorFormatter

  import Ecto.Changeset

  @type t :: %__MODULE__{
          user_id: integer(),
          card_id: String.t(),
          bank: String.t(),
          pdf_pw: String.t(),
          file: Plug.Upload.t()
        }

  defstruct [:user_id, :card_id, :bank, :pdf_pw, :file]

  defmodule Validator do
    use Ecto.Schema
    import Ecto.Changeset

    @supported_banks Application.compile_env(:kachingko_api, :supported_banks)
    @derive {Jason.Encoder, only: [:card_id, :user_id, :bank, :pdf_pw, :file]}

    @allowed_extensions Application.compile_env(
                          :kachingko_api,
                          [:file_upload, :allowed_extensions],
                          [".pdf"]
                        )
    @primary_key false
    embedded_schema do
      field :file, :any, virtual: true
      field :card_id, :string
      field :bank, :string
      field :user_id, :integer
      field :pdf_pw, :string
    end

    def changeset(params) do
      %__MODULE__{}
      |> cast(params, [:file, :card_id, :bank, :user_id, :pdf_pw])
      |> validate_required([:file, :card_id, :bank, :user_id, :pdf_pw])
      |> validate_bank()
      |> validate_file()
      |> format_errors()
    end

    defp validate_file(%{changes: %{file: %Plug.Upload{} = file}} = changeset) do
      changeset
      |> validate_file_type(file)
    end

    defp validate_file(changeset) do
      changeset
      # add_error(
      #   changeset,
      #   :file,
      #   "PDF statement attachment is required"
      # )
    end

    defp validate_bank(%Ecto.Changeset{valid?: true, changes: changes} = changeset) do
      if String.downcase(changes.bank) in @supported_banks do
        changeset
      else
        add_error(
          changeset,
          :bank,
          "Unsupported bank. Please contact the admin to request bank support."
        )
      end
    end

    defp validate_bank(changeset), do: changeset

    defp validate_file_type(changeset, %{filename: filename}) do
      extension = Path.extname(filename) |> String.downcase()

      if extension in @allowed_extensions do
        changeset
      else
        add_error(
          changeset,
          :file,
          "Unsupported file type. Supported files (.pdf)"
        )
      end
    end

    defp format_errors(%Ecto.Changeset{valid?: false} = changeset) do
      # |> validate_required([:file, :card_id, :bank, :user_id, :pdf_pw])
      field_labels = %{
        file: "PDF statement attachment",
        card: "Credit Card",
        bank: "Bank",
        pdf_pw: "Password"
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
          file: validated_data.file,
          bank: validated_data.bank,
          user_id: validated_data.user_id,
          card_id: validated_data.card_id,
          pdf_pw: validated_data.pdf_pw
        }

        Result.ok(command)

      %Ecto.Changeset{valid?: false} = changeset ->
        Result.error(ValidatorFormatter.first_errors_by_field(changeset))
    end
  end
end
