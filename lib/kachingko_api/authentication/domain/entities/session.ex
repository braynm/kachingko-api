defmodule KachingkoApi.Authentication.Domain.Entities.Session do
  alias KachingkoApi.Shared.Result

  @type t :: %__MODULE__{
          user_id: String.t(),
          jti: String.t(),
          aud: String.t(),
          typ: String.t()
        }

  defstruct [:user_id, :jti, :typ, :aud, :expires_at]

  # 7 days
  @default_expiry_hours 24 * 7
  @default_audience "web"

  def new(attrs) do
    # expires_at = attrs[:expires_at] || default_expiry()
    expires_at = attrs[:expires_at]
    jti = attrs[:jti] || generate_jti()
    typ = attrs[:typ]
    aud = attrs[:aud] || @default_audience

    session = %__MODULE__{
      user_id: attrs[:user_id],
      jti: jti,
      aud: aud,
      typ: typ,
      expires_at: expires_at
    }

    Result.ok(session)
  end

  def expired?(%__MODULE__{} = session) do
    DateTime.compare(DateTime.utc_now(), session.expires_at) == :gt
  end

  def valid?(%__MODULE__{} = session) do
    not expired?(session)
  end

  def extend_expiry(%__MODULE__{} = session, hours \\ @default_expiry_hours) do
    new_expiry = DateTime.add(DateTime.utc_now(), hours * 3600, :second)
    %{session | expires_at: new_expiry}
  end

  def new_web(attrs) do
    new(Map.put(attrs, :aud, "web"))
  end

  # defp default_expiry do
  #   DateTime.add(DateTime.utc_now(), @default_expiry_hours * 3600, :second)
  # end

  defp generate_jti do
    :crypto.strong_rand_bytes(16) |> Base.url_encode64(padding: false)
  end
end
