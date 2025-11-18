defmodule KachingkoApi.Authentication.Infra.EctoUserRepository do
  @behaviour KachingkoApi.Authentication.Domain.Repositories.UserRepository

  import Ecto.Query
  alias KachingkoApi.Repo
  alias KachingkoApi.Shared.{Result, Errors}
  alias KachingkoApi.Authentication.Domain.Entities.User
  alias KachingkoApi.Authentication.Infra.Schemas.UserSchema

  @impl true
  def save(%User{id: nil} = user) do
    attrs = %{
      email: User.email_string(user),
      password_hash: user.password_hash
    }

    %UserSchema{}
    |> UserSchema.changeset(attrs)
    |> Repo.insert()
    |> case do
      {:ok, schema} -> Result.ok(to_domain(schema))
      {:error, changeset} -> Result.error(changeset_to_error(changeset))
    end
  end

  @impl true
  def get_by_email(email) when is_binary(email) do
    case Repo.get_by(UserSchema, email: email) do
      nil -> Result.error(%Errors.NotFoundError{message: "User not found", resource: :user})
      schema -> Result.ok(to_domain(schema))
    end
  end

  @impl true
  def get_by_id(id) when is_integer(id) do
    case Repo.get(UserSchema, id) do
      nil ->
        Result.error(%Errors.NotFoundError{message: "User not found", resource: :user})

      schema ->
        Result.ok(to_domain(schema))
    end
  end

  @impl true
  def email_exists?(email) when is_binary(email) do
    Repo.exists?(from u in UserSchema, where: u.email == ^email)
  end

  defp to_domain(%UserSchema{} = schema) do
    %User{
      id: schema.id,
      email: schema.email,
      password_hash: schema.password_hash,
      created_at: schema.inserted_at,
      updated_at: schema.updated_at,
      two_factor_enabled: schema.two_factor_enabled,
      two_factor_backup_codes: schema.two_factor_backup_codes,
      two_factor_secret: schema.two_factor_secret,
      two_factor_method: schema.two_factor_method
    }
  end

  defp to_schema(%User{} = user) do
    %UserSchema{
      id: user.id,
      email: user.email,
      password_hash: user.password_hash
    }
  end

  defp changeset_to_error(%Ecto.Changeset{errors: errors}) do
    {_field, {message, _}} = List.first(errors)
    %Errors.ValidationError{message: message}
  end

  @impl true
  def enable_two_factor(user, secret, backup_codes) do
    {:ok, user_entity} = get_by_id(user.id)
    user_schema = to_schema(user_entity)

    UserSchema.two_factor_changeset(user_schema, %{
      two_factor_enabled: true,
      two_factor_method: user.two_factor_method,
      two_factor_secret: secret,
      two_factor_backup_codes: backup_codes,
      two_factor_enabled_at: DateTime.utc_now()
    })
    |> Repo.update()
    |> case do
      {:ok, schema} -> {:ok, to_domain(schema)}
      error -> error
    end
  end

  @impl true
  def disable_two_factor(user) do
    {:ok, user_schema} = get_by_id(user.id)

    UserSchema.two_factor_changeset(user_schema, %{
      two_factor_enabled: false,
      two_factor_secret: nil,
      two_factor_backup_codes: nil
    })
    |> Repo.update()
    |> case do
      # {:ok, schema} -> {:ok, to_domain(schema)}
      {:ok, schema} -> {:ok, schema}
      error -> error
    end
  end

  @impl true
  def update_two_factor_settings(user, attrs) do
    {:ok, user_schema} = get_by_id(user.id)

    user_schema
    |> UserSchema.two_factor_changeset(attrs)
    |> Repo.update()
    |> case do
      {:ok, schema} -> {:ok, to_domain(schema)}
      error -> error
    end
  end
end
