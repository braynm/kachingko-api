defmodule KachingkoApi.Statements.Infra.Parsers.EastWestParserTest do
  use ExUnit.Case, async: true
  alias KachingkoApi.Statements.Infra.Parsers.EastWestParser
  alias KachingkoApi.Statements.Domain.ValueObjects.Amount

  describe "parse/1" do
    test "successfully parses valid EastWest statement with single page" do
      extracted_texts = [
        [
          [~c"EASTWEST", ~c"CREDIT", ~c"CARD", ~c"STATEMENT"],
          [~c"Statement", ~c"Date", ~c"JAN", ~c"31", ~c"2024"],
          [~c"ACCOUNT", ~c"NUMBER:", ~c"1234567890123456"],
          [~c"SALE", ~c"POST", ~c"CURRENCY", ~c"PESO"],
          [~c"DATE", ~c"DATE", ~c"DESCRIPTION", ~c"AMOUNT"],
          [~c"", ~c"", ~c"", ~c""],
          [~c"", ~c"", ~c"", ~c""],
          [~c"", ~c"", ~c"", ~c""],
          [~c"", ~c"", ~c"", ~c""],
          [~c"", ~c"", ~c"", ~c""],
          [~c"JAN", ~c"15", ~c"JAN", ~c"16", ~c"GROCERY", ~c"STORE", ~c"ABC", ~c"1,234.56"],
          [~c"JAN", ~c"17", ~c"JAN", ~c"18", ~c"GAS", ~c"STATION", ~c"XYZ", ~c"2,500.00"],
          [~c"JAN", ~c"20", ~c"JAN", ~c"21", ~c"CSHPYMNT", ~c"VIA", ~c"ATM", ~c"-5,000.00"],
          [~c"IMPORTANT", ~c"PAYMENT", ~c"ADVICE:", ~c"..."]
        ]
      ]

      assert {:ok, transactions} = EastWestParser.parse(extracted_texts)
      assert length(transactions) == 3

      [txn1, txn2, txn3] = transactions

      # First transaction
      assert txn1.encrypted_details == "GROCERY STORE ABC"
      assert Amount.to_string(txn1.encrypted_amount) == "123456"
      assert txn1.sale_date
      assert txn1.posted_date

      # Second transaction
      assert txn2.encrypted_details == "GAS STATION XYZ"
      assert Amount.to_string(txn2.encrypted_amount) == "250000"

      # Third transaction (payment normalized)
      assert txn3.encrypted_details == "PAYMENT"
      assert Amount.to_string(txn3.encrypted_amount) == "-500000"
    end

    test "successfully parses multi-page EastWest statement" do
      extracted_texts = [
        [
          [~c"EASTWEST", ~c"CREDIT", ~c"CARD", ~c"STATEMENT"],
          [~c"Statement", ~c"Date", ~c"FEB", ~c"28", ~c"2024"],
          [~c"SALE", ~c"POST", ~c"CURRENCY", ~c"PESO"],
          [~c"TRANSACTION", ~c"DESCRIPTION"],
          [~c"DATE", ~c"DATE", ~c"AMOUNT", ~c"AMOUNT"],
          [],
          [],
          [],
          [~c"FEB", ~c"15", ~c"FEB", ~c"16", ~c"GROCERY", ~c"STORE", ~c"1,234.56"],
          [~c"FEB", ~c"17", ~c"FEB", ~c"18", ~c"GAS", ~c"STATION", ~c"2,500.00"],
          [~c"IMPORTANT", ~c"PAYMENT", ~c"ADVICE:", ~c"..."]
        ],
        [
          [~c"SALE", ~c"POST", ~c"CURRENCY", ~c"PESO"],
          [~c"TRANSACTION", ~c"DESCRIPTION"],
          [~c"DATE", ~c"DATE", ~c"AMOUNT", ~c"AMOUNT"],
          [~c"FEB", ~c"20", ~c"FEB", ~c"21", ~c"RESTAURANT", ~c"ABC", ~c"850.00"],
          [~c"FEB", ~c"22", ~c"FEB", ~c"23", ~c"ATM PAYMENT", ~c"-3,000.00"],
          [~c"Total", ~c"Statement", ~c"Balance", ~c"9999.61"],
          [~c"***END", ~c"OF", ~c"STATEMENT***"]
        ]
      ]

      assert {:ok, transactions} = EastWestParser.parse(extracted_texts)
      assert length(transactions) == 4

      # Check that transactions from both pages are included
      descriptions = Enum.map(transactions, & &1.encrypted_details)
      assert "GROCERY STORE" in descriptions
      assert "GAS STATION" in descriptions
      assert "RESTAURANT ABC" in descriptions
      assert "PAYMENT" in descriptions
    end

    test "handles statement with END OF STATEMENT marker" do
      extracted_texts = [
        [
          [~c"Statement", ~c"Date", ~c"MAR", ~c"31", ~c"2024"],
          [~c"SALE", ~c"POST", ~c"CURRENCY", ~c"PESO"],
          [~c"", ~c"", ~c"", ~c""],
          [~c"", ~c"", ~c"", ~c""],
          [~c"", ~c"", ~c"", ~c""],
          [~c"", ~c"", ~c"", ~c""],
          [~c"", ~c"", ~c"", ~c""],
          [~c"MAR", ~c"15", ~c"MAR", ~c"16", ~c"TEST", ~c"TRANSACTION", ~c"100.00"],
          [],
          [~c"***END", ~c"OF", ~c"STATEMENT***"],
          [~c"FOOTER", ~c"INFO"]
        ]
      ]

      assert {:ok, transactions} = EastWestParser.parse(extracted_texts)
      assert length(transactions) == 1
      assert hd(transactions).encrypted_details == "TEST TRANSACTION"
    end

    test "normalizes different payment transaction types" do
      extracted_texts = [
        [
          [~c"Statement", ~c"Date", ~c"APR", ~c"30", ~c"2024"],
          [~c"SALE", ~c"POST", ~c"CURRENCY", ~c"PESO"],
          [~c"", ~c"", ~c"", ~c""],
          [~c"", ~c"", ~c"", ~c""],
          [~c"", ~c"", ~c"", ~c""],
          [~c"", ~c"", ~c"", ~c""],
          [~c"", ~c"", ~c"", ~c""],
          [~c"APR", ~c"15", ~c"APR", ~c"16", ~c"CSHPYMNT", ~c"VIA", ~c"ATM", ~c"-1,000.00"],
          [~c"APR", ~c"16", ~c"APR", ~c"17", ~c"CSHPYMNT", ~c"ONLINE", ~c"-2,000.00"],
          [~c"APR", ~c"17", ~c"APR", ~c"18", ~c"ATM PAYMENT", ~c"-3,000.00"],
          [~c"APR", ~c"18", ~c"APR", ~c"19", ~c"REGULAR", ~c"PURCHASE", ~c"500.00"],
          [~c"IMPORTANT", ~c"PAYMENT", ~c"ADVICE:", ~c"..."]
        ]
      ]

      assert {:ok, transactions} = EastWestParser.parse(extracted_texts)
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
          [~c"Statement", ~c"Date", ~c"MAY", ~c"31", ~c"2024"],
          [~c"SALE", ~c"POST", ~c"CURRENCY", ~c"PESO"],
          [~c"", ~c"", ~c"", ~c""],
          [~c"", ~c"", ~c"", ~c""],
          [~c"", ~c"", ~c"", ~c""],
          [~c"", ~c"", ~c"", ~c""],
          [~c"", ~c"", ~c"", ~c""],
          [~c"MAY", ~c"15", ~c"MAY", ~c"16", ~c"POSITIVE", ~c"AMT", ~c"1,234.56"],
          [~c"MAY", ~c"16", ~c"MAY", ~c"17", ~c"NEGATIVE", ~c"AMT", ~c"-2,500.00"],
          [~c"MAY", ~c"17", ~c"MAY", ~c"18", ~c"SMALL", ~c"AMT", ~c"5.00"],
          [~c"MAY", ~c"18", ~c"MAY", ~c"19", ~c"LARGE", ~c"AMT", ~c"-50,000.00"],
          [~c"IMPORTANT", ~c"PAYMENT", ~c"ADVICE:", ~c"..."]
        ]
      ]

      assert {:ok, transactions} = EastWestParser.parse(extracted_texts)
      assert length(transactions) == 4

      amounts = Enum.map(transactions, &Amount.to_string(&1.encrypted_amount))
      assert "123456" in amounts
      assert "-250000" in amounts
      assert "500" in amounts
      assert "-5000000" in amounts
    end

    test "handles foreign currency transactions" do
      extracted_texts = [
        [
          [~c"Statement", ~c"Date", ~c"JUN", ~c"30", ~c"2024"],
          [~c"SALE", ~c"POST", ~c"CURRENCY", ~c"PESO"],
          [~c"", ~c"", ~c"", ~c""],
          [~c"", ~c"", ~c"", ~c""],
          [~c"", ~c"", ~c"", ~c""],
          [~c"", ~c"", ~c"", ~c""],
          [~c"", ~c"", ~c"", ~c""],
          [
            ~c"JUN",
            ~c"15",
            ~c"JUN",
            ~c"16",
            ~c"FOREIGN",
            ~c"PURCHASE",
            ~c"USD",
            ~c"100.50",
            ~c"5,234.56"
          ],
          [~c"JUN", ~c"16", ~c"JUN", ~c"17", ~c"LOCAL", ~c"PURCHASE", ~c"1,000.00"],
          [~c"IMPORTANT", ~c"PAYMENT", ~c"ADVICE:", ~c"..."]
        ]
      ]

      assert {:ok, transactions} = EastWestParser.parse(extracted_texts)
      assert length(transactions) == 2

      [foreign_txn, local_txn] = transactions

      # Foreign currency transaction should use PHP amount, not USD
      assert foreign_txn.encrypted_details == "FOREIGN PURCHASE"
      assert Amount.to_string(foreign_txn.encrypted_amount) == "523456"

      # Local transaction
      assert local_txn.encrypted_details == "LOCAL PURCHASE"
      assert Amount.to_string(local_txn.encrypted_amount) == "100000"
    end

    test "handles year rollover correctly for December/January transactions" do
      extracted_texts = [
        [
          [~c"Statement", ~c"Date", ~c"JAN", ~c"31", ~c"2024"],
          [~c"SALE", ~c"POST", ~c"CURRENCY", ~c"PESO"],
          [~c"", ~c"", ~c"", ~c""],
          [~c"", ~c"", ~c"", ~c""],
          [~c"", ~c"", ~c"", ~c""],
          [~c"", ~c"", ~c"", ~c""],
          [~c"", ~c"", ~c"", ~c""],
          [~c"DEC", ~c"20", ~c"DEC", ~c"21", ~c"DECEMBER", ~c"TXN", ~c"1,000.00"],
          [~c"JAN", ~c"15", ~c"JAN", ~c"16", ~c"JANUARY", ~c"TXN", ~c"2,000.00"],
          [~c"IMPORTANT", ~c"PAYMENT", ~c"ADVICE:", ~c"..."]
        ]
      ]

      assert {:ok, transactions} = EastWestParser.parse(extracted_texts)
      assert length(transactions) == 2

      [dec_txn, jan_txn] = transactions

      # December transaction should be in 2023 (previous year)
      assert dec_txn.encrypted_details == "DECEMBER TXN"
      assert dec_txn.sale_date.year == 2023
      assert dec_txn.posted_date.year == 2023

      # January transaction should be in 2024 (statement year)
      assert jan_txn.encrypted_details == "JANUARY TXN"
      assert jan_txn.sale_date.year == 2024
      assert jan_txn.posted_date.year == 2024
    end

    test "returns error for malformed extracted text (non-list)" do
      assert {:error, :malformed_extracted_text} = EastWestParser.parse("not a list")
      assert {:error, :malformed_extracted_text} = EastWestParser.parse(nil)
      assert {:error, :malformed_extracted_text} = EastWestParser.parse(%{})
    end

    test "returns error for empty transaction list" do
      extracted_texts = [
        [
          [~c"EASTWEST", ~c"CREDIT", ~c"CARD", ~c"STATEMENT"],
          [~c"Statement", ~c"Date", ~c"JUL", ~c"31", ~c"2024"],
          [~c"ACCOUNT", ~c"NUMBER:", ~c"1234567890123456"]
        ]
      ]

      assert {:error, :empty_list} = EastWestParser.parse(extracted_texts)
    end

    test "handles statement with no transaction header" do
      extracted_texts = [
        [
          [~c"EASTWEST", ~c"CREDIT", ~c"CARD", ~c"STATEMENT"],
          [~c"Statement", ~c"Date", ~c"AUG", ~c"31", ~c"2024"],
          [~c"ACCOUNT", ~c"NUMBER:", ~c"1234567890123456"],
          [~c"SOME", ~c"OTHER", ~c"DATA"]
        ]
      ]

      assert {:error, :empty_list} = EastWestParser.parse(extracted_texts)
    end

    test "filters out incomplete transaction rows" do
      extracted_texts = [
        [
          [~c"Statement", ~c"Date", ~c"SEP", ~c"30", ~c"2024"],
          [~c"SALE", ~c"POST", ~c"CURRENCY", ~c"PESO"],
          [~c"", ~c"", ~c"", ~c""],
          [~c"", ~c"", ~c"", ~c""],
          [~c"", ~c"", ~c"", ~c""],
          [~c"", ~c"", ~c"", ~c""],
          [~c"", ~c"", ~c"", ~c""],
          [~c"SEP", ~c"15", ~c"SEP", ~c"16", ~c"COMPLETE", ~c"TXN", ~c"100.00"],
          # Incomplete row
          [~c"SEP", ~c"16", ~c"SEP", ~c"17"],
          # Incomplete row  
          [~c"SEP", ~c"17"],
          # Empty row
          [],
          [~c"SEP", ~c"18", ~c"SEP", ~c"19", ~c"ANOTHER", ~c"COMPLETE", ~c"200.00"],
          [~c"IMPORTANT", ~c"PAYMENT", ~c"ADVICE:", ~c"..."]
        ]
      ]

      assert {:ok, transactions} = EastWestParser.parse(extracted_texts)
      assert length(transactions) == 2

      descriptions = Enum.map(transactions, & &1.encrypted_details)
      assert "COMPLETE TXN" in descriptions
      assert "ANOTHER COMPLETE" in descriptions
    end

    test "handles different statement date formats" do
      extracted_texts = [
        [
          [~c"EASTWEST", ~c"Statement", ~c"Date", ~c"OCT", ~c"31", ~c"2024"],
          [~c"SALE", ~c"POST", ~c"CURRENCY", ~c"PESO"],
          [~c"", ~c"", ~c"", ~c""],
          [~c"", ~c"", ~c"", ~c""],
          [~c"", ~c"", ~c"", ~c""],
          [~c"", ~c"", ~c"", ~c""],
          [~c"", ~c"", ~c"", ~c""],
          [~c"OCT", ~c"15", ~c"OCT", ~c"16", ~c"TEST", ~c"TXN", ~c"100.00"],
          [~c"IMPORTANT", ~c"PAYMENT", ~c"ADVICE:", ~c"..."]
        ]
      ]

      assert {:ok, transactions} = EastWestParser.parse(extracted_texts)
      assert length(transactions) == 1
      assert hd(transactions).encrypted_details == "TEST TXN"
    end

    test "handles transactions with zero amounts" do
      extracted_texts = [
        [
          [~c"Statement", ~c"Date", ~c"NOV", ~c"30", ~c"2024"],
          [~c"SALE", ~c"POST", ~c"CURRENCY", ~c"PESO"],
          [~c"", ~c"", ~c"", ~c""],
          [~c"", ~c"", ~c"", ~c""],
          [~c"", ~c"", ~c"", ~c""],
          [~c"", ~c"", ~c"", ~c""],
          [~c"", ~c"", ~c"", ~c""],
          [~c"NOV", ~c"15", ~c"NOV", ~c"16", ~c"ZERO", ~c"AMOUNT", ~c"0.00"],
          [~c"IMPORTANT", ~c"PAYMENT", ~c"ADVICE:", ~c"..."]
        ]
      ]

      assert {:ok, transactions} = EastWestParser.parse(extracted_texts)
      assert length(transactions) == 1
      assert Amount.to_string(hd(transactions).encrypted_amount) == "0"
    end

    test "handles very long transaction descriptions" do
      long_description_parts = [
        "VERY",
        "LONG",
        "DESCRIPTION",
        "WITH",
        "MANY",
        "WORDS",
        "THAT",
        "SPANS",
        "MULTIPLE",
        "TOKENS"
      ]

      long_description_charlists = Enum.map(long_description_parts, &String.to_charlist/1)

      extracted_texts = [
        [
          [~c"Statement", ~c"Date", ~c"DEC", ~c"31", ~c"2024"],
          [~c"SALE", ~c"POST", ~c"CURRENCY", ~c"PESO"],
          [~c"", ~c"", ~c"", ~c""],
          [~c"", ~c"", ~c"", ~c""],
          [~c"", ~c"", ~c"", ~c""],
          [~c"", ~c"", ~c"", ~c""],
          [~c"", ~c"", ~c"", ~c""],
          [~c"DEC", ~c"15", ~c"DEC", ~c"16"] ++ long_description_charlists ++ [~c"100.00"],
          [~c"IMPORTANT", ~c"PAYMENT", ~c"ADVICE:", ~c"..."]
        ]
      ]

      assert {:ok, transactions} = EastWestParser.parse(extracted_texts)
      assert length(transactions) == 1
      assert String.contains?(hd(transactions).encrypted_details, "VERY LONG DESCRIPTION")
    end

    test "handles mixed foreign currency scenarios" do
      extracted_texts = [
        [
          [~c"Statement", ~c"Date", ~c"JAN", ~c"31", ~c"2025"],
          [~c"SALE", ~c"POST", ~c"CURRENCY", ~c"PESO"],
          [~c"", ~c"", ~c"", ~c""],
          [~c"", ~c"", ~c"", ~c""],
          [~c"", ~c"", ~c"", ~c""],
          [~c"", ~c"", ~c"", ~c""],
          [~c"", ~c"", ~c"", ~c""],
          # Invalid foreign amount
          [
            ~c"JAN",
            ~c"15",
            ~c"JAN",
            ~c"16",
            ~c"FOREIGN",
            ~c"TXN",
            ~c"INVALID",
            ~c"ABC",
            ~c"5,000.00"
          ],
          [~c"JAN", ~c"16", ~c"JAN", ~c"17", ~c"ANOTHER", ~c"TXN", ~c"2,000.00"],
          [~c"IMPORTANT", ~c"PAYMENT", ~c"ADVICE:", ~c"..."]
        ]
      ]

      assert {:ok, transactions} = EastWestParser.parse(extracted_texts)
      assert length(transactions) == 2

      [txn1, txn2] = transactions

      # First transaction should keep invalid foreign currency as part of description
      assert txn1.encrypted_details == "FOREIGN TXN INVALID ABC"
      assert Amount.to_string(txn1.encrypted_amount) == "500000"

      # Second transaction normal
      assert txn2.encrypted_details == "ANOTHER TXN"
      assert Amount.to_string(txn2.encrypted_amount) == "200000"
    end
  end
end
