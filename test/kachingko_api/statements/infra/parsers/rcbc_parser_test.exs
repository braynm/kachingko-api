defmodule KachingkoApi.Statements.Infra.Parsers.RcbcParserTest do
  use ExUnit.Case, async: true
  alias KachingkoApi.Statements.Infra.Parsers.RcbcParser
  alias KachingkoApi.Statements.Domain.ValueObjects.Amount

  describe "parse/1" do
    test "successfully parses valid RCBC statement with single page" do
      extracted_texts = [
        [
          [~c"RCBC", ~c"CREDIT", ~c"CARD", ~c"STATEMENT"],
          [~c"ACCOUNT", ~c"NUMBER:", ~c"1234567890123456"],
          [~c"SALE", ~c"DATE", ~c"POST", ~c"DATE", ~c"DESCRIPTION", ~c"AMOUNT"],
          [~c"", ~c"", ~c"", ~c"", ~c"", ~c""],
          [~c"", ~c"", ~c"", ~c"", ~c"", ~c""],
          [~c"01/15/24", ~c"01/16/24", ~c"GROCERY", ~c"STORE", ~c"ABC", ~c"1,234.56"],
          [~c"01/17/24", ~c"01/18/24", ~c"GAS", ~c"STATION", ~c"XYZ", ~c"2,500.00-"],
          [~c"01/20/24", ~c"01/21/24", ~c"CASH PAYMENT VIA ATM", ~c"5,000.00-"],
          [~c"PAGE", ~c"1", ~c"of", ~c"1"]
        ]
      ]

      assert {:ok, transactions} = RcbcParser.parse(extracted_texts)
      assert length(transactions) == 3

      [txn1, txn2, txn3] = transactions

      # First transaction
      assert txn1.encrypted_details == "GROCERY STORE ABC"
      assert Amount.to_string(txn1.encrypted_amount) == "123456"
      assert txn1.sale_date
      assert txn1.posted_date

      # Second transaction (negative amount)
      assert txn2.encrypted_details == "GAS STATION XYZ"
      assert Amount.to_string(txn2.encrypted_amount) == "-250000"

      # Third transaction (payment normalized)
      assert txn3.encrypted_details == "PAYMENT"
      assert Amount.to_string(txn3.encrypted_amount) == "-500000"
    end

    test "successfully parses multi-page RCBC statement" do
      extracted_texts = [
        [
          [~c"RCBC", ~c"CREDIT", ~c"CARD", ~c"STATEMENT"],
          [~c"SALE", ~c"DATE", ~c"POST", ~c"DATE", ~c"DESCRIPTION", ~c"AMOUNT"],
          [~c"", ~c"", ~c"", ~c"", ~c"", ~c""],
          [~c"", ~c"", ~c"", ~c"", ~c"", ~c""],
          [~c"01/15/24", ~c"01/16/24", ~c"GROCERY", ~c"STORE", ~c"1,234.56"],
          [~c"01/17/24", ~c"01/18/24", ~c"GAS", ~c"STATION", ~c"2,500.00"],
          [~c"PAGE", ~c"1", ~c"of", ~c"2"]
        ],
        [
          [~c"SALE", ~c"DATE", ~c"POST", ~c"DATE", ~c"DESCRIPTION", ~c"AMOUNT"],
          [~c"", ~c"", ~c"", ~c"", ~c"", ~c""],
          [~c"01/20/24", ~c"01/21/24", ~c"RESTAURANT", ~c"ABC", ~c"850.00"],
          [~c"01/22/24", ~c"01/23/24", ~c"ATM PAYMENT", ~c"3,000.00-"],
          [~c"BALANCE", ~c"END", ~c"OF", ~c"STATEMENT"]
        ]
      ]

      assert {:ok, transactions} = RcbcParser.parse(extracted_texts)
      assert length(transactions) == 4

      # Check that transactions from both pages are included
      descriptions = Enum.map(transactions, & &1.encrypted_details)
      assert "GROCERY STORE" in descriptions
      assert "GAS STATION" in descriptions
      assert "RESTAURANT ABC" in descriptions
      assert "PAYMENT" in descriptions
    end

    test "handles statement with BALANCE END marker" do
      extracted_texts = [
        [
          [~c"SALE", ~c"DATE", ~c"POST", ~c"DATE", ~c"DESCRIPTION", ~c"AMOUNT"],
          [~c"", ~c"", ~c"", ~c"", ~c"", ~c""],
          [~c"", ~c"", ~c"", ~c"", ~c"", ~c""],
          [~c"01/15/24", ~c"01/16/24", ~c"TEST", ~c"TRANSACTION", ~c"100.00"],
          [~c"BALANCE", ~c"END", ~c"OF", ~c"STATEMENT", ~c"5,000.00"],
          [~c"PAGE", ~c"1", ~c"of", ~c"1"]
        ]
      ]

      assert {:ok, transactions} = RcbcParser.parse(extracted_texts)
      assert length(transactions) == 1
      assert hd(transactions).encrypted_details == "TEST TRANSACTION"
    end

    test "normalizes different payment transaction types" do
      extracted_texts = [
        [
          [~c"SALE", ~c"DATE", ~c"POST", ~c"DATE", ~c"DESCRIPTION", ~c"AMOUNT"],
          [~c"", ~c"", ~c"", ~c"", ~c"", ~c""],
          [~c"", ~c"", ~c"", ~c"", ~c"", ~c""],
          [~c"01/15/24", ~c"01/16/24", ~c"CASH PAYMENT VIA ATM", ~c"1,000.00-"],
          [~c"01/16/24", ~c"01/17/24", ~c"CASH PAYMENT ONLINE", ~c"2,000.00-"],
          [~c"01/17/24", ~c"01/18/24", ~c"ATM PAYMENT", ~c"3,000.00-"],
          [~c"01/18/24", ~c"01/19/24", ~c"REGULAR", ~c"PURCHASE", ~c"500.00"],
          [~c"PAGE", ~c"1", ~c"of", ~c"1"]
        ]
      ]

      assert {:ok, transactions} = RcbcParser.parse(extracted_texts)
      assert length(transactions) == 4

      payment_txns = Enum.filter(transactions, &(&1.encrypted_details == "PAYMENT"))
      regular_txns = Enum.filter(transactions, &(&1.encrypted_details != "PAYMENT"))

      assert length(payment_txns) == 3
      assert length(regular_txns) == 1
      assert hd(regular_txns).encrypted_details == "REGULAR PURCHASE"
    end

    test "handles amounts with various formats" do
      extracted_texts = [
        [
          [~c"SALE", ~c"DATE", ~c"POST", ~c"DATE", ~c"DESCRIPTION", ~c"AMOUNT"],
          [~c"", ~c"", ~c"", ~c"", ~c"", ~c""],
          [~c"", ~c"", ~c"", ~c"", ~c"", ~c""],
          [~c"01/15/24", ~c"01/16/24", ~c"POSITIVE", ~c"AMT", ~c"1,234.56"],
          [~c"01/16/24", ~c"01/17/24", ~c"NEGATIVE", ~c"AMT", ~c"2,500.00-"],
          [~c"01/17/24", ~c"01/18/24", ~c"SMALL", ~c"AMT", ~c"5.00"],
          [~c"01/18/24", ~c"01/19/24", ~c"LARGE", ~c"AMT", ~c"50,000.00-"],
          [~c"PAGE", ~c"1", ~c"of", ~c"1"]
        ]
      ]

      assert {:ok, transactions} = RcbcParser.parse(extracted_texts)
      assert length(transactions) == 4

      amounts = Enum.map(transactions, &Amount.to_string(&1.encrypted_amount))
      assert "123456" in amounts
      assert "-250000" in amounts
      assert "500" in amounts
      assert "-5000000" in amounts
    end

    test "returns error for malformed extracted text (non-list)" do
      assert {:error, :malformed_extracted_text} = RcbcParser.parse("not a list")
      assert {:error, :malformed_extracted_text} = RcbcParser.parse(nil)
      assert {:error, :malformed_extracted_text} = RcbcParser.parse(%{})
    end

    test "returns error for empty transaction list" do
      extracted_texts = [
        [
          [~c"RCBC", ~c"CREDIT", ~c"CARD", ~c"STATEMENT"],
          [~c"ACCOUNT", ~c"NUMBER:", ~c"1234567890123456"]
        ]
      ]

      assert {:error, :empty_list} = RcbcParser.parse(extracted_texts)
    end

    test "handles statement with no transaction header" do
      extracted_texts = [
        [
          [~c"RCBC", ~c"CREDIT", ~c"CARD", ~c"STATEMENT"],
          [~c"ACCOUNT", ~c"NUMBER:", ~c"1234567890123456"],
          [~c"SOME", ~c"OTHER", ~c"DATA"]
        ]
      ]

      assert {:error, :empty_list} = RcbcParser.parse(extracted_texts)
    end

    test "filters out incomplete transaction rows" do
      extracted_texts = [
        [
          [~c"SALE", ~c"DATE", ~c"POST", ~c"DATE", ~c"DESCRIPTION", ~c"AMOUNT"],
          [~c"", ~c"", ~c"", ~c"", ~c"", ~c""],
          [~c"", ~c"", ~c"", ~c"", ~c"", ~c""],
          [~c"01/15/24", ~c"01/16/24", ~c"COMPLETE", ~c"TXN", ~c"100.00"],
          # Incomplete row
          [~c"01/16/24", ~c"01/17/24"],
          # Incomplete row
          [~c"01/17/24"],
          # Empty row
          [],
          [~c"01/18/24", ~c"01/19/24", ~c"ANOTHER", ~c"COMPLETE", ~c"200.00"],
          [~c"PAGE", ~c"1", ~c"of", ~c"1"]
        ]
      ]

      assert {:ok, transactions} = RcbcParser.parse(extracted_texts)
      assert length(transactions) == 2

      descriptions = Enum.map(transactions, &Map.get(&1, :encrypted_details))
      assert "COMPLETE TXN" in descriptions
      assert "ANOTHER COMPLETE" in descriptions
    end

    test "handles statements with multiple balance end markers" do
      extracted_texts = [
        [
          [~c"SALE", ~c"DATE", ~c"POST", ~c"DATE", ~c"DESCRIPTION", ~c"AMOUNT"],
          [~c"", ~c"", ~c"", ~c"", ~c"", ~c""],
          [~c"", ~c"", ~c"", ~c"", ~c"", ~c""],
          [~c"01/15/24", ~c"01/16/24", ~c"TXN", ~c"1", ~c"100.00"],
          [~c"BALANCE", ~c"END", ~c"PARTIAL"],
          [~c"01/17/24", ~c"01/18/24", ~c"TXN", ~c"2", ~c"200.00"],
          [~c"BALANCE", ~c"END", ~c"OF", ~c"STATEMENT"],
          [~c"PAGE", ~c"1", ~c"of", ~c"1"]
        ]
      ]

      assert {:ok, transactions} = RcbcParser.parse(extracted_texts)
      # Should stop at first BALANCE END marker
      assert length(transactions) == 1
      assert hd(transactions).encrypted_details == "TXN 1"
    end
  end
end
