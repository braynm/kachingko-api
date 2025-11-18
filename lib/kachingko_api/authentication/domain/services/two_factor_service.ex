defmodule KachingkoApi.Authentication.Domain.Services.TwoFactorService do
  alias KachingkoApi.Authentication.Domain.Entities.User
  alias KachingkoApi.Authentication.Domain.Services.TOTP
  alias KachingkoApi.Authentication.Infra.EctoUserRepository
  alias KachingkoApi.Shared.Result

  def initiate_setup(%User{} = user) do
    secret = TOTP.generate_secret()
    provisioning_data = TOTP.get_provisioning_data(user, secret)
    Result.ok(Map.put(provisioning_data, :secret, Base.encode32(secret)))
  end

  def complete_setup(%User{} = user, secret, code) when is_binary(secret) and is_binary(code) do
    user_with_2fa = %{user | two_factor_secret: secret, two_factor_method: "totp"}

    with true <- TOTP.verify_code(user_with_2fa, code) do
      backup_codes = generate_backup_codes()
      hashed_codes = hash_backup_codes(backup_codes)

      case EctoUserRepository.enable_two_factor(user_with_2fa, secret, hashed_codes) do
        {:ok, updated_user} -> {:ok, updated_user, backup_codes}
        error -> error
      end
    else
      false -> {:error, :invalid_code}
      error -> error
    end
  end

  def complete_setup(_, _, _), do: {:error, :invalid_params}

  def disable(%User{} = user) do
  end

  def verify_code(user, code) do
    cond do
      not user.two_factor_enabled ->
        {:error, :disabled}

      TOTP.verify_code(user, code) ->
        {:ok, :valid}

      verify_backup_code(user, code) ->
        {:ok, :backup_code_used}

      true ->
        {:error, :invalid_code}
    end
  end

  def is_enabled?(user), do: user.two_factor_enabled

  defp generate_backup_codes(count \\ 10) do
    for _ <- 1..count do
      :crypto.strong_rand_bytes(4) |> Base.encode16(case: :lower)
    end
  end

  defp hash_backup_codes(codes) do
    Enum.map(codes, &Bcrypt.hash_pwd_salt/1)
  end

  defp verify_backup_code(%{two_factor_backup_codes: codes}, code) when is_list(codes) do
    Enum.any?(codes, &Bcrypt.verify_pass(code, &1))
  end

  defp verify_backup_code(_, _), do: false
end
