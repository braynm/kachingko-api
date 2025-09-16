defmodule KachingkoApi.Statements.Domain.ValueObjects.FileChecksum do
  @moduledoc """
  File checksum value object for duplicate detection for uploading
  """

  defstruct [:value]
  alias KachingkoApi.Shared.Result

  @type t :: %__MODULE__{
          value: String.t()
        }

  @algorithm :sha256

  def new(file_content)

  @doc """
  Makes a new FileChecksum struct with `:sha256` as default algo.
  """
  def new(file_content) do
    hash_value =
      @algorithm
      |> :crypto.hash(file_content)
      |> Base.encode32(case: :lower)

    Result.ok(%__MODULE__{value: hash_value})
  end

  def to_string(%__MODULE__{value: value}), do: value
  def equals?(%__MODULE__{value: v1}, %__MODULE__{value: v2}), do: v1 == v2

  def valid?(%__MODULE__{value: value}) when is_binary(value) do
    String.length(value) > 0
  end

  def valid?(_), do: false
end
