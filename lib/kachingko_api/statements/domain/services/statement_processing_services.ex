defmodule KachingkoApi.Statements.Domain.Services.StatementProcessingServices do
  alias KachingkoApi.Shared.Pagination
  alias KachingkoApi.Statements.PdfExtractor
  alias KachingkoApi.Statements.Domain.Services.FileProcessor
  alias KachingkoApi.Statements.Infra.EctoTransactionRepository
  alias KachingkoApi.Statements.Infra.EctoTransactionMetaRepository
  alias KachingkoApi.Statements.Domain.Services.DuplicateChecker
  alias KachingkoApi.Statements.Domain.Services.SaveStatementService

  defstruct [
    :file_processor,
    :duplicate_checker,
    :pdf_extractor,
    :save_statement_service,
    :txn_repository,
    :txn_meta_repository,
    :transaction_fn,
    :pagination
  ]

  def default do
    %__MODULE__{
      file_processor: FileProcessor,
      pdf_extractor: PdfExtractor,
      duplicate_checker: DuplicateChecker,
      save_statement_service: SaveStatementService,
      txn_repository: EctoTransactionRepository,
      txn_meta_repository: EctoTransactionMetaRepository,
      pagination: Pagination,
      transaction_fn: nil
    }
  end
end
