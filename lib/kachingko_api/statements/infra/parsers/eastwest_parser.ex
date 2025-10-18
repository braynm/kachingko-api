defmodule KachingkoApi.Statements.Infra.Parsers.EastWestParser do
  @moduledoc """
  EastWest-specific PDF parser implementation
  All amounts are treated as PHP currency

  This parser processes EastWest credit card statements that have been extracted from PDF format.
  The parser expects extracted text in a nested list format where:
  - First level: Pages
  - Second level: Rows per page
  - Third level: Words/tokens per row

  Example input structure:
  [
    [["EastWest", "STATEMENT"], ["ACCOUNT", "123456"]],  # Page 1
    [["PREVIOUS", "STATEMENT", "BALANCE"], ["JAN", "15", "JAN", "16", "GROCERY", "1,234.56"]]  # Page 2
  ]
  """

  alias KachingkoApi.Utils.DateTimezone
  alias KachingkoApi.Statements.Domain.ValueObjects.Amount
  @behaviour KachingkoApi.Statements.Domain.BankParser

  # Markers used to identify the start and end of transaction data in EastWest statements
  # TODO: some statement have no "PREVIOUS STATEMENT BALANCE" text for first's card
  # transaction. We need to differentiate per pair

  @doc """
  Main parsing function that orchestrates the entire EastWest statement parsing process.

  Takes extracted text from PDF and returns structured transaction data.
  The parsing pipeline follows these steps:
  1. Converts charlists to strings for all text elements
  2. Find the page containing transactions
  3. Extract the transaction rows between markers
  4. Normalize each transaction row into a structured format

  ## Parameters
  - extracted_texts: List of pages, each containing rows of tokenized text

  ## Returns
  - List of transaction maps with keys: :sale_date, :post_date, :desc, :amount
  - {:error, :malformed_extracted_text} if input is not a list
  """
  @impl true
  def parse(extracted_texts) when is_list(extracted_texts) do
    extracted_texts = charlist_to_sigil(extracted_texts)

    statement_date = find_statement_date(extracted_texts)

    txns =
      extracted_texts
      |> find_transaction_page()
      |> find_transaction_list()
      |> normalize_and_to_transaction(statement_date)

    case txns do
      {:error, error} -> {:error, error}
      [] -> {:error, :empty_list}
      txns when is_list(txns) -> {:ok, txns}
    end
  end

  def parse(_), do: {:error, :malformed_extracted_text}

  # Finds the statement date from extracted text for year calculation
  defp find_statement_date(extracted_texts) when is_list(extracted_texts) do
    matched_statement_date =
      extracted_texts
      |> Enum.flat_map(& &1)
      |> Enum.find(fn txt ->
        match?(["Statement", "Date" | _rest], txt) or
          match?([_, "Statement", "Date" | _rest], txt)
      end)

    case matched_statement_date do
      ["Statement", "Date" | rest] -> rest
      [_, "Statement", "Date" | rest] -> rest
    end
  end

  # Convert charlists to strings for consistent processing
  defp charlist_to_sigil(extracted_texts) when is_list(extracted_texts) do
    Enum.map(extracted_texts, fn page ->
      Enum.map(page, fn row -> Enum.map(row, &to_string/1) end)
    end)
  end

  defp charlist_to_sigil(_extracted_texts), do: parse(nil)

  # Filter pages that contain transaction data based on header pattern
  defp find_transaction_page(extracted_texts) when is_list(extracted_texts) do
    Enum.filter(extracted_texts, fn txt_list ->
      Enum.any?(txt_list, &match?(["SALE", "POST", "CURRENCY", "PESO"], &1))
    end)
  end

  # Extract transaction rows between header and footer markers
  defp find_transaction_list(extracted_texts) when is_list(extracted_texts) do
    extracted_texts
    |> Enum.with_index()
    |> Enum.flat_map(fn
      {txts, 0} ->
        # TODO: make this regex for more accurate parsing
        header_index =
          Enum.find_index(
            txts,
            &match?(["SALE", "POST", "CURRENCY", "PESO"], &1)
          ) + 6

        end_of_page_index =
          Enum.find_index(
            txts,
            &match?(["IMPORTANT", "PAYMENT", "ADVICE:" | _], &1)
          )

        end_of_bal? = Enum.find_index(txts, &match?(["***END", "OF", "STATEMENT***"], &1))

        end_txn_marker =
          if not is_nil(end_of_bal?), do: end_of_bal? - 2, else: end_of_page_index - 1

        Enum.slice(txts, header_index..end_txn_marker)

      {txts, _} ->
        header_index =
          Enum.find_index(
            txts,
            &match?(["SALE", "POST", "CURRENCY", "PESO"], &1)
          ) + 3

        end_of_bal? = Enum.find_index(txts, &match?(["***END", "OF", "STATEMENT***"], &1)) - 2

        Enum.slice(txts, header_index..end_of_bal?)
    end)
  end

  defp find_transaction_list(_), do: parse(nil)

    # Convert raw transaction rows into structured transaction maps
  defp normalize_and_to_transaction(result, statement_date) when is_list(result) do
    [st_month, _, year] =
      statement_date

    Enum.map(result, fn txn ->
      months = %{
        "JAN" => "01",
        "FEB" => "02",
        "MAR" => "03",
        "APR" => "04",
        "MAY" => "05",
        "JUN" => "06",
        "JUL" => "07",
        "AUG" => "08",
        "SEP" => "09",
        "OCT" => "10",
        "NOV" => "11",
        "DEC" => "12"
      }

      with [sale_m, sale_d, post_m, post_d | rest] <- txn do
        case split_txn_desc_and_amount(rest) do
          {nil, nil} ->
            %{}

          {amt, desc} ->
            sale_year =
              if st_month == "JAN" and months[sale_m] in ["11", "12"] do
                String.to_integer(year) - 1
              else
                year
              end

            post_year =
              if st_month == "JAN" and months[post_m] in ["11", "12"] do
                String.to_integer(year) - 1
              else
                year
              end


            details = maybe_normalize_payment_txn(Enum.join(desc, " "))
            {category, subcategory} = 
                KachingkoApi.Statements.TransactionCategorizer.categorize(details)

            %{
              encrypted_details: details,
              encrypted_amount: normalize_amt(amt),
              category: category, 
              subcategory: subcategory, 
              sale_date: to_utc_datetime("#{sale_year}-#{months[sale_m]}-#{sale_d}"),
              posted_date: to_utc_datetime("#{post_year}-#{months[post_m]}-#{post_d}")
            }
        end
      else
        _ -> %{}
      end
    end)
    |> Enum.filter(&(&1 !== %{}))
  end

  defp normalize_and_to_transaction(_result, _), do: parse(nil)

  # normalize description for payment txns
  # to make query faster
  defp maybe_normalize_payment_txn(desc) do
    # normalize description for payment txns
    # to make query faster
    case desc do
      "CSHPYMNT" <> _ -> "PAYMENT"
      "ATM PAYMENT" -> "PAYMENT"
      _ -> desc
    end
  end

  # Match monetary amounts: optional negative, digits with optional commas, optional decimal
  defp split_txn_desc_and_amount([]), do: {nil, nil}

  defp split_txn_desc_and_amount(txn) do
    [amount | middle_reversed] = Enum.reverse(txn)

    transaction_parts =
      middle_reversed
      |> maybe_remove_foreign_currency()
      |> Enum.reverse()

    {amount, transaction_parts}
  end

  # Split transaction parts into description and amount components
  # Handle foreign currency transactions by removing foreign amounts
  defp maybe_remove_foreign_currency([foreign_amt, currency | rest] = txn)
       when byte_size(currency) == 3 do
    if String.match?(foreign_amt, ~r/^-?\d{1,3}(?:,\d{3})*(?:\.\d+)?$/),
      do: rest,
      else: txn
  end

  defp maybe_remove_foreign_currency(parts), do: parts

  # Normalize amount string to Amount struct
  defp normalize_amt(amt) do
    amt = String.trim(amt)
    {:ok, amt} = Amount.new(amt)

    amt
  end

  # Convert date string to UTC datetime for storage
  defp to_utc_datetime(date_str_iso8601) do
    DateTimezone.from_pdf("#{date_str_iso8601} 00:00:00")
  end

  @impl true
  def supported_bank, do: "eastwest"
end
