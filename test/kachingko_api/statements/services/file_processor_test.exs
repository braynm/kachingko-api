defmodule KachingkoApi.Statements.Domain.Services.FileProcessorTest do
  use ExUnit.Case
  alias KachingkoApi.Statements.Domain.Services.FileProcessor
  alias KachingkoApi.Shared.Result

  @tmp_dir System.tmp_dir!()

  # Helper to create a real temp file for File.read to work with
  defp create_temp_file(filename, content) do
    path = Path.join(@tmp_dir, filename)
    File.write!(path, content)
    path
  end

  defp cleanup_file(path), do: File.rm(path)

  describe "read_and_validate/2" do
    test "successfully validates and reads valid PDF file" do
      # Create real file for File.read
      temp_path = create_temp_file("test.pdf", "real PDF content")

      upload = %Plug.Upload{
        path: temp_path,
        filename: "document.pdf",
        content_type: "application/pdf"
      }

      # Mock only File.stat to return valid size
      mock_file_stat = fn _path ->
        # 5MB - under limit
        {:ok, %{size: 5_000_000}}
      end

      result = FileProcessor.read_and_validate(upload, mock_file_stat)

      assert {:ok, "real PDF content"} = result

      cleanup_file(temp_path)
    end

    test "rejects file that exceeds size limit" do
      upload = %Plug.Upload{
        # Path doesn't matter since we're mocking stat
        path: "/any/path.pdf",
        filename: "large.pdf",
        content_type: "application/pdf"
      }

      # Mock File.stat to return oversized file
      mock_file_stat = fn _path ->
        # 15MB - over limit
        {:ok, %{size: 15_000_000}}
      end

      result = FileProcessor.read_and_validate(upload, mock_file_stat)

      assert {:error, "File size 15000000 bytes exceeds maximum of 10000000 bytes"} = result
    end

    test "rejects invalid file type" do
      upload = %Plug.Upload{
        # Path doesn't matter since we're mocking stat
        path: "/any/path.jpg",
        filename: "large.jpg",
        content_type: "image/jpg"
      }

      # Mock File.stat to return oversized file
      mock_file_stat = fn _path ->
        # 15MB - over limit
        {:ok, %{size: 10_000_000}}
      end

      result = FileProcessor.read_and_validate(upload, mock_file_stat)

      assert {:error, {:invalid_file_type, [allowed: [".pdf"], received: ".jpg"]}} = result
    end

    test "handles File.stat error (file not found)" do
      upload = %Plug.Upload{
        path: "/nonexistent/missing.pdf",
        filename: "missing.pdf",
        content_type: "application/pdf"
      }

      # Mock File.stat to return error
      mock_file_stat = fn _path ->
        {:error, :enoent}
      end

      result = FileProcessor.read_and_validate(upload, mock_file_stat)

      assert {:error, "Cannot read file: enoent"} = result
    end

    test "rejects invalid file extension (File.stat not called)" do
      upload = %Plug.Upload{
        path: "/any/path.jpg",
        filename: "image.jpg",
        content_type: "image/jpeg"
      }

      # Mock File.stat (won't be called due to extension validation first)
      mock_file_stat = fn _path ->
        {:ok, %{size: 2_000_000}}
      end

      result = FileProcessor.read_and_validate(upload, mock_file_stat)

      expected_error = Result.error({:invalid_file_type, allowed: [".pdf"], received: ".jpg"})
      assert expected_error == result
    end

    test "passes size validation but fails on File.read (real file error)" do
      upload = %Plug.Upload{
        # This file doesn't exist
        path: "/nonexistent/fake.pdf",
        filename: "fake.pdf",
        content_type: "application/pdf"
      }

      # Mock File.stat to return valid size
      mock_file_stat = fn _path ->
        # Valid size
        {:ok, %{size: 3_000_000}}
      end

      result = FileProcessor.read_and_validate(upload, mock_file_stat)

      # Real File.read will fail because file doesn't exist
      expected_error = Result.error({:file_read_error, :enoent})
      assert expected_error == result
    end

    test "successfully reads actual file content" do
      # Create real file with specific content
      content = "This is actual PDF content from file"
      temp_path = create_temp_file("real.pdf", content)

      upload = %Plug.Upload{
        path: temp_path,
        filename: "real.pdf",
        content_type: "application/pdf"
      }

      # Mock File.stat but let File.read work normally
      mock_file_stat = fn _path ->
        # Mock a valid size
        {:ok, %{size: 8_000_000}}
      end

      result = FileProcessor.read_and_validate(upload, mock_file_stat)

      # Should get the actual file content
      assert {:ok, "This is actual PDF content from file"} = result

      cleanup_file(temp_path)
    end

    test "accepts exactly max file size" do
      temp_path = create_temp_file("max_size.pdf", "content")

      upload = %Plug.Upload{
        path: temp_path,
        filename: "max_size.pdf",
        content_type: "application/pdf"
      }

      # Mock File.stat to return exactly max size
      mock_file_stat = fn _path ->
        # Exactly 10MB
        {:ok, %{size: 10_000_000}}
      end

      result = FileProcessor.read_and_validate(upload, mock_file_stat)

      assert {:ok, "content"} = result

      cleanup_file(temp_path)
    end

    test "rejects file 1 byte over limit" do
      upload = %Plug.Upload{
        path: "/any/path.pdf",
        filename: "over_limit.pdf",
        content_type: "application/pdf"
      }

      # Mock File.stat to return 1 byte over
      mock_file_stat = fn _path ->
        # 1 byte over 10MB
        {:ok, %{size: 10_000_001}}
      end

      result = FileProcessor.read_and_validate(upload, mock_file_stat)

      assert {:error, "File size 10000001 bytes exceeds maximum of 10000000 bytes"} = result
    end
  end

  describe "file extension validation (no mocking needed)" do
    test "handles case insensitive extensions" do
      upload = %Plug.Upload{
        path: "/any/path.PDF",
        filename: "FILE.PDF",
        content_type: "application/pdf"
      }

      # Mock valid file size
      mock_file_stat = fn _path -> {:ok, %{size: 1_000_000}} end

      # This would fail on File.read since path doesn't exist, 
      # but passes extension validation
      result = FileProcessor.read_and_validate(upload, mock_file_stat)

      # Will fail on File.read, not extension validation
      assert {:error, {:file_read_error, :enoent}} = result
    end

    test "rejects empty extension" do
      upload = %Plug.Upload{
        path: "/any/path",
        filename: "file_no_extension",
        content_type: "application/pdf"
      }

      mock_file_stat = fn _path -> {:ok, %{size: 1_000_000}} end

      result = FileProcessor.read_and_validate(upload, mock_file_stat)

      expected_error = Result.error({:invalid_file_type, allowed: [".pdf"], received: ""})
      assert expected_error == result
    end
  end
end
