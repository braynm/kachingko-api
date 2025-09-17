defmodule KachingkoApi.Statements.Application.Handlers.UploadStatementHandler do
  alias KachingkoApi.Repo
  alias KachingkoApi.Statements.Infra.Parsers.RcbcParser
  alias KachingkoApi.Statements.Infra.Parsers.EastWestParser
  alias KachingkoApi.Statements.Domain.ValueObjects.FileChecksum
  alias KachingkoApi.Statements.Domain.Services.StatementProcessingServices
  alias KachingkoApi.Statements.Application.Commands.UploadStatementTransaction

  def handle(%UploadStatementTransaction{} = command, deps) do
    %StatementProcessingServices{
      file_processor: file_processor,
      duplicate_checker: duplicate_checker,
      pdf_extractor: pdf_extractor,
      save_statement_service: save_statement_service,
      transaction_fn: transaction_fn
    } = deps

    transaction_fn = transaction_fn || (&default_transaction/1)

    result =
      transaction_fn.(fn ->
        with %Plug.Upload{path: tmp_path, filename: filename} <- command.file,
             {:ok, binary_file} <- file_processor.read_and_validate(command.file),
             {:ok, checksum} <- FileChecksum.new(binary_file),
             :ok <- duplicate_checker.check_duplicate(command.user_id, checksum),
             {:ok, extracted_texts} <-
               pdf_extractor.extract_texts(tmp_path, command.pdf_pw),
             {:ok, extracted_txns} <- txn_parse(command.bank, extracted_texts),
             {:ok, saved_txns} <-
               save_statement_and_transaction(
                 save_statement_service,
                 extracted_txns,
                 command,
                 filename,
                 checksum
               ) do
          saved_txns
        else
          {:error, error} ->
            # something went wrong. Lets rollback.
            Repo.rollback(error)
        end
      end)

    case result do
      {:ok, txns} -> {:ok, txns}
      {:error, error} -> {:error, error}
    end
  end

  defp save_statement_and_transaction(save_stmnt_service, txns, command, filename, checksum) do
    save_stmnt_service.save_statement_and_transaction(%{
      "filename" => filename,
      "file_checksum" => checksum,
      "user_id" => command.user_id,
      "card_id" => command.card_id,
      "txns" => txns
    })
  end

  defp txn_parse(bank, extracted_texts) do
    case String.downcase(bank) do
      "rcbc" -> RcbcParser.parse(extracted_texts)
      "eastwest" -> EastWestParser.parse(extracted_texts)
      _ -> {:error, :unsupported_bank}
    end
  end

  defp default_transaction(fun) do
    Repo.transaction(fun)
  end
end
