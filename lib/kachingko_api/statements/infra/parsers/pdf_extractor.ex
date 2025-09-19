defmodule KachingkoApi.Statements.PdfExtractor do
  use GenServer

  @python_module :pdf_extractor

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def extract_texts(pdf_path, password) do
    GenServer.call(__MODULE__, {:extract, pdf_path, password})
  end

  def init(_) do
    # Remove :name from Python options, it's not supported
    {:ok, py} =
      :python.start(python_path: ~c"priv", python: ~c"python3")

    {:ok, %{py: py}}
  end

  def handle_call({:extract, path, password}, _from, %{py: py} = state) do
    result =
      :python.call(py, @python_module, :extract_all_tables, [
        path,
        password
      ])

    {:reply, result, state}
  end
end
