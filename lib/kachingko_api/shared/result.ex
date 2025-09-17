defmodule KachingkoApi.Shared.Result do
  @moduledoc """
  Result type for domain operations.

  This module provides a Result type and utility functions for handling success/error cases
  in a functional programming style. It implements a monad-like pattern that allows for
  elegant error handling and composition of operations that may fail.

  The Result type is represented as a tagged tuple:
  - `{:ok, value}` for successful operations
  - `{:error, reason}` for failed operations

  ## Examples

      iex> KachingkoApi.Shared.Result.ok("success")
      {:ok, "success"}

      iex> KachingkoApi.Shared.Result.error("failed")
      {:error, "failed"}

      iex> {:ok, 5} |> KachingkoApi.Shared.Result.map(&(&1 * 2))
      {:ok, 10}

      iex> {:error, "fail"} |> KachingkoApi.Shared.Result.map(&(&1 * 2))
      {:error, "fail"}
  """

  @type t(success, error) :: {:ok, success} | {:error, error}
  @type t(success) :: t(success, term())

  @doc """
  Creates a successful result with the given value.

  ## Parameters
  - `value` - The success value to wrap

  ## Examples

      iex> KachingkoApi.Shared.Result.ok("hello")
      {:ok, "hello"}

      iex> KachingkoApi.Shared.Result.ok(42)
      {:ok, 42}
  """
  def ok(value), do: {:ok, value}

  @doc """
  Creates an error result with the given reason.

  ## Parameters
  - `reason` - The error reason to wrap

  ## Examples

      iex> KachingkoApi.Shared.Result.error("not found")
      {:error, "not found"}

      iex> KachingkoApi.Shared.Result.error(:invalid_input)
      {:error, :invalid_input}
  """
  def error(reason), do: {:error, reason}

  @doc """
  Maps a function over the success value of a Result.

  If the Result is `{:ok, value}`, applies the function to the value and wraps
  the result in `{:ok, new_value}`. If the Result is an error, returns the error unchanged.

  This is useful for transforming success values while preserving error states.

  ## Parameters
  - `result` - A Result tuple (`{:ok, value}` or `{:error, reason}`)
  - `func` - A function to apply to the success value

  ## Examples

      iex> {:ok, 5} |> KachingkoApi.Shared.Result.map(&(&1 * 2))
      {:ok, 10}

      iex> {:error, "failed"} |> KachingkoApi.Shared.Result.map(&(&1 * 2))
      {:error, "failed"}

      iex> {:ok, "hello"} |> KachingkoApi.Shared.Result.map(&String.upcase/1)
      {:ok, "HELLO"}
  """
  def map({:ok, value}, func), do: {:ok, func.(value)}
  def map({:error, _} = error, _func), do: error

  @doc """
  Binds a function that returns a Result to the success value of a Result.

  If the Result is `{:ok, value}`, applies the function to the value and returns
  the Result directly (allowing for chaining of operations that may fail).
  If the Result is an error, returns the error unchanged.

  This is also known as "flatMap" in other functional programming languages.
  Use this when your function already returns a Result type.

  ## Parameters
  - `result` - A Result tuple (`{:ok, value}` or `{:error, reason}`)
  - `func` - A function that takes a value and returns a Result

  ## Examples

      iex> divide = fn x -> if x != 0, do: {:ok, 10 / x}, else: {:error, :division_by_zero} end
      iex> {:ok, 2} |> KachingkoApi.Shared.Result.bind(divide)
      {:ok, 5.0}

      iex> {:ok, 0} |> KachingkoApi.Shared.Result.bind(divide)
      {:error, :division_by_zero}

      iex> {:error, "initial error"} |> KachingkoApi.Shared.Result.bind(divide)
      {:error, "initial error"}
  """
  def bind({:ok, value}, func), do: func.(value)
  def bind({:error, _} = error, _func), do: error
end
