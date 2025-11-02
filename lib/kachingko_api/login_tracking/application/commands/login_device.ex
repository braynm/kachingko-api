defmodule KachingkoApi.LoginTracking.Application.Commands.LoginDevice do
  alias KachingkoApi.Shared.Result
  alias KachingkoApi.Utils.ValidatorFormatter
  alias KachingkoApi.LoginTracking.Application.ValueObjects.Authentication

  @type t :: %__MODULE__{
          ip_address: String.t(),
          fingerprint: String.t(),
          screen_resolution: String.t(),
          timezone: String.t(),
          language: String.t(),
          browserName: String.t(),
          osName: String.t(),
          platform: String.t()
        }

  defstruct [
    :ip_address,
    :fingerprint,
    :screen_resolution,
    :timezone,
    :language,
    :browserName,
    :osName,
    :platform
  ]

  defmodule Validator do
    use Ecto.Schema
    import Ecto.Changeset

    @derive {Jason.Encoder,
             only: [
               :ip_address,
               :fingerprint,
               :screen_resolution,
               :timezone,
               :language,
               :browserName,
               :osName,
               :platform
             ]}

    @primary_key false
    embedded_schema do
      field :ip_address, :string
      field :fingerprint, :string
      field :screen_resolution, :string
      field :timezone, :string
      field :language, :string
      field :browserName, :string
      field :osName, :string
      field :platform, :string
    end

    def changeset(params) do
      %__MODULE__{}
      |> cast(params, [
        :ip_address,
        :fingerprint,
        :screen_resolution,
        :timezone,
        :language,
        :browserName,
        :osName,
        :platform
      ])
      |> validate_required([
        :ip_address,
        :fingerprint,
        :screen_resolution,
        :timezone,
        :language,
        :browserName,
        :osName,
        :platform
      ])
    end
  end

  def new(params) do
    case Validator.changeset(params) do
      %Ecto.Changeset{valid?: true} = changeset ->
        validated_data = Ecto.Changeset.apply_changes(changeset)

        command = %__MODULE__{
          ip_address: validated_data.ip_address,
          fingerprint: validated_data.fingerprint,
          screen_resolution: validated_data.screen_resolution,
          timezone: validated_data.timezone,
          language: validated_data.language,
          browserName: validated_data.browserName,
          osName: validated_data.osName,
          platform: validated_data.platform
        }

        Result.ok(command)

      %Ecto.Changeset{valid?: false} = changeset ->
        Result.error(ValidatorFormatter.first_errors_by_field(changeset))
    end
  end

  def from_guardian_opts(%Authentication{} = params) do
    new(Map.from_struct(params))
  end
end
