defmodule KachingkoApi.KachingkoApi.ListStatementTransactionTest do
  use ExUnit.Case, async: true

  import Double

  alias KachingkoApi.Repo
  alias KachingkoApi.Statements
  alias KachingkoApi.Test.Doubles

  alias KachingkoApi.Statements.Infra.EctoTransactionRepository
  alias KachingkoApi.Statements.Infra.Schemas.TransactionSchema

  setup _ do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
  end

  @tag :statements
  describe "Statements.list_user_transaction/3" do
    @tag :statements
    test "list empty users transaction" do
      user_id = 11
      params = []

      assert {:ok, %{metadata: %{}, entries: []}} =
               Statements.list_user_transaction(
                 user_id,
                 params,
                 Doubles.list_statement_txns_double()
               )
    end

    @tag :statements
    test "list users transaction with 1 item/s" do
      user_id = 11
      params = [limit: 1]

      assert {:ok, %{metadata: metadata, entries: list}} =
               Statements.list_user_transaction(
                 user_id,
                 params,
                 Doubles.list_statement_txns_double(txns())
               )

      next_page =
        "eyJpZCI6ImIxZjE4ZGMzLTQ2YTQtNGUxNC1hMGVjLTc2NDdkMDAyMWZmNCIsInNhbGVfZGF0ZSI6IjIwMjUtMDQtMjFUMDA6MDA6MDBaIn0"

      [itm1] = list
      assert itm1.encrypted_details == "TIEZA NAIA T3 PASAY PH"
      assert itm1.encrypted_amount == "3240"
      assert metadata.limit == 1
      assert metadata.next_cursor == next_page
      assert length(list) == 1
    end
  end

  defp txns do
    %{
      txn_repository:
        EctoTransactionRepository
        |> stub(:list_user_transaction, fn _ -> TransactionSchema end)
        |> stub(:all, fn _ ->
          [
            %TransactionSchema{
              id: "b1f18dc3-46a4-4e14-a0ec-7647d0021ff4",
              user_id: 11,
              statement_id: "e5b7c87b-936c-41ef-b26a-3e43f2575765",
              sale_date: ~U[2025-04-21 00:00:00Z],
              posted_date: ~U[2025-04-22 00:00:00Z],
              encrypted_details: "TIEZA NAIA T3 PASAY PH",
              encrypted_amount: "3240",
              inserted_at: ~N[2025-08-11 14:15:49],
              updated_at: ~N[2025-08-11 14:15:49]
            },
            %TransactionSchema{
              id: "0ec67a4e-7a2b-409c-972f-fe1f1c0a0eae",
              user_id: 11,
              statement_id: "e5b7c87b-936c-41ef-b26a-3e43f2575765",
              sale_date: ~U[2025-05-01 00:00:00Z],
              posted_date: ~U[2025-05-01 00:00:00Z],
              encrypted_details: "GADC 246EASTWOOD FC, QUEZON",
              encrypted_amount: "26351.51",
              inserted_at: ~N[2025-08-11 14:15:49],
              updated_at: ~N[2025-08-11 14:15:49]
            }
          ]
        end)
    }
  end
end
