defmodule KachingkoApi.Vault do
  use Cloak.Vault, otp_app: :kachingko_api

  def init(config) do
    config =
      Keyword.put(config, :ciphers,
        default: {Cloak.Ciphers.AES.GCM, tag: "AES.GCM.V1", key: decode_env!("CLOAK_KEY")}
      )

    {:ok, config}
  end

  defp decode_env!(var) do
    key = System.get_env(var)

    if key do
      Base.decode64!(key)
    else
      raise """
      Environment variable #{var} is missing.
      Generate one with: 
      iex> 32 |> :crypto.strong_rand_bytes() |> Base.encode64()
      """
    end
  end
end
