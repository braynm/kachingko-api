defmodule KachingkoApi.KachingkoApi.Authentication.AuthenticationTest do
  use ExUnit.Case, async: true
  # use ExUnit.Case

  alias KachingkoApi.Authentication
  alias KachingkoApi.Test.Doubles

  alias KachingkoApi.Shared.{Result, Errors}
  alias KachingkoApi.Authentication.Domain.Entities.{User, Session}
  alias KachingkoApi.Authentication.Domain.ValueObjects.{Email, Password}
  alias KachingkoApi.Authentication.Domain.Dtos.RegisteredUser

  @tag :authentication
  describe "Authentication.register/4" do
    @tag :authentication
    test "successfully registers user and returns session" do
      deps = %{
        user_repository: Doubles.user_repository_double(),
        session_repository: Doubles.session_repository_double(),
        transaction_fn: Doubles.transaction_fn()
      }

      assert {:ok,
              %{
                user: %RegisteredUser{email: %Email{value: "test@example.com"}},
                session: %Session{jti: "test-jti", aud: "web"},
                token: "test-token"
              }} = Authentication.register("test@example.com", "password123", "web", deps)
    end

    @tag :authentication
    test "fails register on existing email and returns error" do
      user_repo = Doubles.user_repository_double(email_exists?: fn _email -> true end)

      deps = %{
        user_repository: user_repo,
        session_repository: Doubles.session_repository_double(),
        transaction_fn: Doubles.transaction_fn()
      }

      assert Result.error(%Errors.ValidationError{
               message: "Email already exists"
             }) == Authentication.register("test@example.com", "password123", "web", deps)
    end
  end

  @tag :authentication
  describe "Authentication.login/4" do
    test "successfully logins user" do
      user_repo =
        Doubles.user_repository_double(
          get_by_email: fn email ->
            Result.ok(%User{
              id: "test-id",
              email: email,
              password_hash: hash_pw("password123")
            })
          end
        )

      deps = %{
        user_repository: user_repo,
        session_repository: Doubles.session_repository_double(),
        transaction_fn: Doubles.transaction_fn()
      }

      assert {
               :ok,
               %{
                 session:
                   {%KachingkoApi.Authentication.Domain.Entities.Session{
                      aud: "web",
                      user_id: "test-id",
                      updated_at: nil
                    }, "test-token"},
                 user: %KachingkoApi.Authentication.Domain.Dtos.AuthenticatedUser{
                   email: "test@example.com",
                   id: "test-id"
                 }
               }
             } = Authentication.login("test@example.com", "password123", "web", deps)
    end

    @tag :authentication
    test "fail logins user" do
      deps = %{
        user_repository: Doubles.user_repository_double(),
        session_repository: Doubles.session_repository_double(),
        transaction_fn: Doubles.transaction_fn()
      }

      assert {:error, %Errors.AuthenticationError{message: "Invalid credentials"}} ==
               Authentication.login("test@example.com", "password123", "web", deps)
    end
  end

  describe "Authentication.validate_session/4" do
    @tag :authentication
    test "successfully validates token" do
      session_repo =
        Doubles.session_repository_double(
          validate_token: fn _token ->
            Result.ok(%KachingkoApi.Authentication.Domain.Entities.Session{
              user_id: "test-user-id",
              jti: "test-jti",
              aud: "web"
            })
          end
        )

      user_repo =
        Doubles.user_repository_double(
          get_by_id: fn id ->
            Result.ok(%User{
              id: id,
              email: "test@example.com",
              password_hash: hash_pw("password123")
            })
          end
        )

      deps = %{
        user_repository: user_repo,
        session_repository: session_repo,
        transaction_fn: Doubles.transaction_fn()
      }

      assert {:ok,
              %{
                session: %KachingkoApi.Authentication.Domain.Entities.Session{
                  user_id: "test-user-id",
                  jti: "test-jti",
                  aud: "web",
                  expires_at: nil,
                  created_at: nil,
                  updated_at: nil
                },
                user: %KachingkoApi.Authentication.Domain.Entities.User{
                  id: "test-user-id",
                  email: "test@example.com",
                  created_at: nil,
                  updated_at: nil
                }
              }} = Authentication.validate_session("test-token", deps)
    end

    @tag :authentication
    test "fail validates token" do
      session_repo =
        Doubles.session_repository_double(
          validate_token: fn _token ->
            Result.error(%Errors.AuthenticationError{message: "Invalid session"})
          end
        )

      user_repo =
        Doubles.user_repository_double(
          get_by_id: fn id ->
            Result.ok(%User{
              id: id,
              email: "test@example.com",
              password_hash: hash_pw("password123")
            })
          end
        )

      deps = %{
        user_repository: user_repo,
        session_repository: session_repo,
        transaction_fn: Doubles.transaction_fn()
      }

      assert {:error,
              %KachingkoApi.Shared.Errors.AuthenticationError{
                message: "Invalid session"
              }} = Authentication.validate_session("test-token", deps)
    end
  end

  defp hash_pw(password) when is_binary(password) do
    {:ok, pw} = Password.new(password)
    Password.hash(pw)
  end
end
