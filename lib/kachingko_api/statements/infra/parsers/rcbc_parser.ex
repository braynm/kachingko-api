defmodule KachingkoApi.Statements.Infra.Parsers.RcbcParser do
  @moduledoc """
  RCBC-specific PDF parser implementation
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
    txns =
      extracted_texts
      |> charlist_to_sigil()
      |> find_transaction_page()
      |> find_transaction_list()
      |> normalize_and_to_transaction()

    case txns do
      {:error, error} -> {:error, error}
      [] -> {:error, :empty_list}
      txns when is_list(txns) -> {:ok, txns}
    end
  end

  def parse(_), do: {:error, :malformed_extracted_text}

  defp charlist_to_sigil(extracted_texts) when is_list(extracted_texts) do
    Enum.map(extracted_texts, fn page ->
      Enum.map(page, fn row -> Enum.map(row, &to_string/1) end)
    end)
  end

  defp charlist_to_sigil(_extracted_texts), do: parse(nil)

  defp find_transaction_page(extracted_texts) when is_list(extracted_texts) do
    Enum.filter(extracted_texts, fn txt_list ->
      Enum.any?(txt_list, fn txt ->
        case txt do
          ["SALE", "DATE", "POST", "DATE", "DESCRIPTION", "AMOUNT" | _rest] -> true
          _ -> false
        end
      end)
    end)
  end

  defp find_transaction_list(extracted_texts) when is_list(extracted_texts) do
    extracted_texts
    |> Enum.with_index()
    |> Enum.flat_map(fn
      {txts, 0} ->
        # TODO: Pattern match + Regex for more accurate finding of txn items
        header_index =
          Enum.find_index(
            txts,
            &match?(["SALE", "DATE", "POST", "DATE", "DESCRIPTION", "AMOUNT" | _], &1)
          ) + 3

        end_of_page_index =
          Enum.find_index(
            txts,
            &match?(["PAGE", _, "of", _], &1)
          )

        end_of_bal? = Enum.find_index(txts, &match?(["BALANCE", "END" | _], &1))

        end_txn_marker =
          if not is_nil(end_of_bal?), do: end_of_bal? - 1, else: end_of_page_index - 1

        Enum.slice(txts, header_index..end_txn_marker)

      {txts, _} ->
        header_index =
          Enum.find_index(
            txts,
            &match?(["SALE", "DATE", "POST", "DATE", "DESCRIPTION", "AMOUNT" | _], &1)
          ) + 2

        end_of_bal? = Enum.find_index(txts, &match?(["BALANCE", "END" | _], &1)) - 1

        Enum.slice(txts, header_index..end_of_bal?)
    end)
  end

  defp find_transaction_list(_), do: parse(nil)

  defp maybe_normalize_payment_txn(desc) do
    # normalize description for payment txns
    # to make query faster
    case desc do
      "CASH PAYMENT" <> _ -> "PAYMENT"
      "ATM PAYMENT" -> "PAYMENT"
      _ -> desc
    end
  end

  defp normalize_and_to_transaction(result) when is_list(result) do
    Enum.map(result, fn txn ->
      case txn do
        [sale_date, post_date | rest] ->
          %{}

          case Enum.split(rest, -1) do
            {[], []} ->
              %{}

            {desc, [amt]} ->
              %{
                sale_date: to_utc_datetime(sale_date),
                posted_date: to_utc_datetime(post_date),
                encrypted_details: maybe_normalize_payment_txn(Enum.join(desc, " ")),
                encrypted_amount: normalize_amt(amt)
              }
          end

        _ ->
          %{}
      end

      # [sale_date, post_date | rest] = txn
    end)
    # |> Enum.filter(&(&1 !== %{}))
    |> Enum.filter(fn txn ->
      # txn !== %{} and not String.starts_with?(txn.encrypted_details, "REV")
      txn !== %{}
    end)
  end

  defp normalize_and_to_transaction(_result), do: parse(nil)

  defp normalize_amt(amt) do
    amt = String.trim(amt)

    amt =
      if String.ends_with?(amt, "-") do
        "-#{String.trim_trailing(amt, "-")}"
      else
        amt
      end

    {:ok, amt} = Amount.new(amt)

    amt
  end

  # def to_iso8601(date_str) do
  #   [mm, dd, yy] = String.split(date_str, "/")
  #   full_year = "20" <> yy
  #
  #   {:ok, date} =
  #     Date.new(String.to_integer(full_year), String.to_integer(mm), String.to_integer(dd))
  #
  #   {:ok, datetime} = DateTime.new(date, ~T[00:00:00], "Etc/UTC")
  #   datetime
  # end

  defp to_utc_datetime(date_str) do
    [mm, dd, yy] = String.split(date_str, "/")
    full_year = "20" <> yy

    DateTimezone.from_pdf("#{full_year}-#{mm}-#{dd} 00:00:00")
  end

  @impl true
  def supported_bank() do
    "rcbc"
  end
end
