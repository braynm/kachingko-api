defmodule KachingkoApi.Statements.Infra.Parsers.EastWestParser do
  @moduledoc """
  EastWest-specific PDF parser implementation
  All amounts are treated as PHP currency

  This parser processes RCBC credit card statements that have been extracted from PDF format.
  The parser expects extracted text in a nested list format where:
  - First level: Pages
  - Second level: Rows per page
  - Third level: Words/tokens per row

  Example input structure:
  [
    [["RCBC", "STATEMENT"], ["ACCOUNT", "123456"]],  # Page 1
    [["PREVIOUS", "STATEMENT", "BALANCE"], ["01/15", "01/16", "GROCERY", "1,234.56-"]]  # Page 2
  ]
  """

  alias KachingkoApi.Utils.DateTimezone
  alias KachingkoApi.Statements.Domain.ValueObjects.Amount
  @behaviour KachingkoApi.Statements.Domain.BankParser

  # Markers used to identify the start and end of transaction data in RCBC statements
  # TODO: some statement have no "PREVIOUS STATEMENT BALANCE" text for first's card
  # transaction. We need to differentiate per pair

  @doc """
  Main parsing function that orchestrates the entire RCBC statement parsing process.

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

  defp find_statement_date(extracted_texts) when is_list(extracted_texts) do
    matched_statement_date =
      extracted_texts
      |> Enum.find(fn txts ->
        Enum.find(txts, &match?(["Statement", "Date" | _rest], &1))
      end)
      |> Enum.find(&match?(["Statement", "Date" | _rest], &1))

    ["Statement", "Date" | rest] = matched_statement_date

    rest
  end

  defp charlist_to_sigil(extracted_texts) when is_list(extracted_texts) do
    Enum.map(extracted_texts, fn page ->
      Enum.map(page, fn row -> Enum.map(row, &to_string/1) end)
    end)
  end

  defp charlist_to_sigil(_extracted_texts), do: parse(nil)

  def find_transaction_page(extracted_texts) when is_list(extracted_texts) do
    Enum.filter(extracted_texts, fn txt_list ->
      Enum.any?(txt_list, &match?(["SALE", "POST", "CURRENCY", "PESO"], &1))
    end)
  end

  defp find_transaction_list(extracted_texts) when is_list(extracted_texts) do
    extracted_texts
    |> Enum.with_index()
    |> IO.inspect()
    |> Enum.flat_map(fn
      {txts, 0} ->
        header_index =
          Enum.find_index(
            txts,
            &match?(["SALE", "POST", "CURRENCY", "PESO"], &1)
          ) + 4

        end_of_page_index =
          Enum.find_index(
            txts,
            &match?(["IMPORTANT", "PAYMENT", "ADVICE:" | _], &1)
          )

        end_of_bal? = Enum.find_index(txts, &match?(["***END", "OF", "STATEMENT***"], &1))

        end_txn_marker =
          if not is_nil(end_of_bal?), do: end_of_bal? - 1, else: end_of_page_index - 1

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

            %{
              encrypted_details: maybe_normalize_payment_txn(Enum.join(desc, " ")),
              encrypted_amount: normalize_amt(amt),
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
  def split_txn_desc_and_amount([]), do: {nil, nil}

  def split_txn_desc_and_amount(txn) do
    [amount | middle_reversed] = Enum.reverse(txn)

    transaction_parts =
      middle_reversed
      |> maybe_remove_foreign_currency()
      |> Enum.reverse()

    {amount, transaction_parts}
  end

  defp maybe_remove_foreign_currency([foreign_amt, currency | rest] = txn)
       when byte_size(currency) == 3 do
    if String.match?(foreign_amt, ~r/^-?\d{1,3}(?:,\d{3})*(?:\.\d+)?$/),
      do: rest,
      else: txn
  end

  defp maybe_remove_foreign_currency(parts), do: parts

  defp normalize_amt(amt) do
    amt = String.trim(amt)
    {:ok, amt} = Amount.new(amt)

    amt
  end

  def to_utc_datetime(date_str_iso8601) do
    DateTimezone.from_pdf("#{date_str_iso8601} 00:00:00")
  end

  def validate_format("eastwest"), do: false
  def supported_bank, do: "eastwest"
end
