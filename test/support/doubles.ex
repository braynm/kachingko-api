defmodule KachingkoApi.Test.Doubles do
  import Double
  alias KachingkoApi.Repo
  alias KachingkoApi.Shared.{Result, Errors}
  alias KachingkoApi.Authentication.Domain.Entities.Session
  alias KachingkoApi.Statements.Domain.Services.StatementProcessingServices
  alias KachingkoApi.Authentication.Domain.Repositories.{UserRepository, SessionRepository}

  alias KachingkoApi.Statements.PdfExtractor
  alias KachingkoApi.Statements.Domain.Entities.Transaction
  alias KachingkoApi.Statements.Domain.Services.FileProcessor
  alias KachingkoApi.Statements.Infra.EctoTransactionRepository
  alias KachingkoApi.Statements.Infra.Schemas.TransactionSchema
  alias KachingkoApi.Statements.Domain.Services.DuplicateChecker
  alias KachingkoApi.Statements.Domain.Services.SaveStatementService

  def user_repository_double(overrides \\ []) do
    defaults = %{
      save: fn user -> Result.ok(%{user | id: "test-user-id"}) end,
      get_by_email: fn _email ->
        Result.error(%Errors.NotFoundError{message: "User not found", resource: :user})
      end,
      get_by_id: fn _id ->
        Result.error(%Errors.NotFoundError{message: "User not found", resource: :user})
      end,
      email_exists?: fn _email -> false end
    }

    # Merge overrides
    impl = Map.merge(defaults, Map.new(overrides))

    UserRepository
    |> stub(:save, impl.save)
    |> stub(:get_by_email, impl.get_by_email)
    |> stub(:get_by_id, impl.get_by_id)
    |> stub(:email_exists?, impl.email_exists?)
  end

  def session_repository_double(overrides \\ []) do
    test_session = %Session{
      user_id: "test-user-id",
      jti: "test-jti",
      aud: "web",
      # 1 hour
      expires_at: DateTime.add(DateTime.utc_now(), 3600, :second)
    }

    defaults = %{
      create_token: fn session ->
        Result.ok({%{session | jti: "test-jti"}, "test-token"})
      end,
      validate_token: fn _token -> Result.ok(test_session) end,
      revoke_token: fn _token -> Result.ok(:ok) end,
      revoke_all_user_tokens: fn _user_id -> Result.ok(:ok) end,
      get_user_sessions: fn _user_id -> Result.ok([test_session]) end,
      cleanup_expired_tokens: fn -> Result.ok(0) end
    }

    impl = Map.merge(defaults, Map.new(overrides))

    SessionRepository
    |> stub(:create_token, impl.create_token)
    |> stub(:validate_token, impl.validate_token)
    |> stub(:revoke_token, impl.revoke_token)
    |> stub(:revoke_all_user_tokens, impl.revoke_all_user_tokens)
    |> stub(:get_user_sessions, impl.get_user_sessions)
    |> stub(:cleanup_expired_tokens, impl.cleanup_expired_tokens)
  end

  def transaction_fn() do
    fn fun ->
      case fun.() do
        %{} = result -> {:ok, result}
        {:error, _} = error -> error
        other -> {:ok, other}
      end
    end
  end

  def statement_process_double(overrides \\ [])

  def statement_process_double(overrides) do
    defaults = %{
      file_processor: file_processor(),
      duplicate_checker: duplicate_checker(),
      pdf_extractor: pdf_extractor(),
      save_statement_service: save_statement_service(),
      transaction_fn: fn fun -> Repo.transaction(fun) end,
      txn_meta_repository: []
    }

    impl = Map.merge(defaults, Map.new(overrides))

    %StatementProcessingServices{
      file_processor: impl.file_processor,
      duplicate_checker: impl.duplicate_checker,
      pdf_extractor: impl.pdf_extractor,
      save_statement_service: impl.save_statement_service,
      transaction_fn: impl.transaction_fn
    }
  end

  def list_statement_txns_double(overrides \\ %{})

  def list_statement_txns_double(overrides) do
    defaults = %{
      # pagination: Pagination |> stub(:paginate, fn _ -> pagination end),
      txn_repository:
        EctoTransactionRepository
        |> stub(:list_user_transaction, fn _ -> TransactionSchema end)
        |> stub(:all, fn _ ->
          []
        end)
    }

    impl = Map.merge(defaults, Map.new(overrides))

    %{
      txn_repository: impl.txn_repository
    }
  end

  defp pdf_extractor do
    PdfExtractor
    |> stub(:extract_texts, fn _, _ -> {:ok, valid_extracted_texts()} end)
  end

  defp file_processor do
    FileProcessor
    |> stub(:read_and_validate, fn _ -> {:ok, "TEST"} end)
  end

  defp duplicate_checker do
    DuplicateChecker
    |> stub(:check_duplicate, fn _, _ -> :ok end)
  end

  defp save_statement_service do
    SaveStatementService
    |> stub(:save_statement_and_transaction, fn _ -> {:ok, valid_inserted_txns()} end)
  end

  # defp save_statement_service do
  #   SaveStatementService
  #   |> stub(:save_statement_and_transaction, fn _ ->
  #     {:ok, valid_inserted_txns()}
  #   end)
  # end

  defp valid_inserted_txns do
    statement_id = Ecto.UUID.generate()
    user_id = Ecto.UUID.generate()

    Enum.map(valid_parsed_txns(), fn txn ->
      txn =
        txn
        |> Map.put(:statement_id, statement_id)
        |> Map.put(:id, user_id)
        |> Map.put(:user_id, 11)
        |> Map.put(:inserted_at, DateTime.utc_now())
        |> Map.put(:updated_at, DateTime.utc_now())

      {:ok, txn} = Transaction.new(txn)

      txn
    end)

    # items =
    #   Enum.map(valid_parsed_txns(), fn item ->
    #     {:ok, txn} = Transaction.from_schema(item)
    #     txn
    #   end)
  end

  defp valid_extracted_texts do
    [
      [[]],
      [
        [
          ~c"SALE",
          ~c"DATE",
          ~c"POST",
          ~c"DATE",
          ~c"DESCRIPTION",
          ~c"AMOUNT",
          ~c"IMPORTANT",
          ~c"REMINDERS"
        ],
        [~c"SALE", ~c"DATE", ~c"POST", ~c"DATE", ~c"DESCRIPTION", ~c"AMOUNT"],
        [~c"06/08/25", ~c"06/09/25", ~c"BONCHON", ~c"MAKILING", ~c"CALAMBA", ~c"PH", ~c"605.00"],
        [~c"06/13/25", ~c"06/16/25", ~c"MERCURYDRUGCORP1016", ~c"CALAMBA", ~c"PH", ~c"105.00"],
        [~c"06/13/25", ~c"06/16/25", ~c"GOLDILOCKS-WALTERMART", ~c"LAGUNA", ~c"PH", ~c"220.00"],
        [~c"999999"],
        [~c"BALANCE", ~c"END"]
      ],
      [[]]
    ]
  end

  defp valid_parsed_txns do
    [
      %{
        sale_date: ~U[2025-06-08 00:00:00Z],
        posted_date: ~U[2025-06-08 00:00:00Z],
        encrypted_details: "BONCHON MAKILING CALAMBA PH",
        encrypted_amount: "605.00",
        category: "Food & Dining",
        subcategory: "Food & Dining"
      },
      %{
        sale_date: ~U[2025-06-13 00:00:00Z],
        posted_date: ~U[2026-06-16 00:00:00Z],
        encrypted_details: "MERCURYDRUGCORP1016 CALAMBA PH",
        encrypted_amount: "105.00",
        category: "Health & Pharmacy",
        subcategory: "Food & Dining"
      },
      %{
        sale_date: ~U[2025-06-13 00:00:00Z],
        posted_date: ~U[2026-06-16 00:00:00Z],
        encrypted_details: "GOLDILOCKS WATLERMART LAGUNA PH",
        encrypted_amount: "220.00",
        category: "Food & Dining",
        subcategory: "Food & Dining"
      }
    ]
  end
end
