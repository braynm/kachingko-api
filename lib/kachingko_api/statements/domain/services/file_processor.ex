defmodule KachingkoApi.Statements.Domain.Services.FileProcessor do
  alias KachingkoApi.Shared.Result

  @max_file_size Application.compile_env(
                   :kachingko_api,
                   [:file_upload, :max_file_size],
                   10_000_000 # 10 MB
                 )
  @allowed_extensions Application.compile_env(
                        :kachingko_api,
                        [:file_upload, :allowed_extensions],
                        [".pdf"]
                      )

  def read_and_validate(%Plug.Upload{} = upload, file_stat_fn \\ &File.stat/1) do
    with :ok <- validate_file_type(upload),
         :ok <- validate_file_size(upload, file_stat_fn),
         {:ok, content} <- read_file_content(upload) do
      Result.ok(content)
    end
  end

  defp validate_file_size(%{path: path}, file_stat_fn) do
    case file_stat_fn.(path)  do
      {:ok, %{size: size}} when size <= @max_file_size ->
        :ok

      {:ok, %{size: size}} ->
        {:error, "File size #{size} bytes exceeds maximum of #{@max_file_size} bytes"}

      {:error, reason} ->
        {:error, "Cannot read file: #{reason}"}
    end

    # Result.error({:file_too_large, max_size: @max_file_size, actual_size: size})
  end

  defp validate_file_size(_, _), do: :ok

  defp validate_file_type(%{filename: filename}) do
    extension = Path.extname(filename) |> String.downcase()

    if extension in @allowed_extensions do
      :ok
    else
      Result.error({:invalid_file_type, allowed: @allowed_extensions, received: extension})
    end
  end

  defp read_file_content(%{path: path}) do
    case File.read(path) do
      {:ok, content} -> Result.ok(content)
      {:error, reason} -> Result.error({:file_read_error, reason})
    end
  end
end
