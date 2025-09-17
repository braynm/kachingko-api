defmodule KachingkoApi.Statements.Application.Commands.ListUserTransaction do
  @enforce_keys []
  defstruct [
    :cursor,
    :sort,
    :filters,
    :limit,
    :queryable,
    :user_id
  ]

  @type t :: %__MODULE__{
          cursor: String.t() | nil,
          sort: [{atom(), :asc | :desc}],
          filters: map(),
          user_id: integer(),
          limit: pos_integer(),
          queryable: Ecto.Queryable.t()
        }

  @default_sort [sale_date: :asc, id: :asc]
  @default_limit 20
  @max_limit 50

  def new(opts \\ [])

  def new(opts) do
    with {:ok, validated_opts} <- validate_options(opts),
         user_id when not is_nil(user_id) <- validated_opts[:user_id] do
      command = %__MODULE__{
        cursor: validated_opts[:cursor],
        user_id: validated_opts[:user_id],
        sort: validated_opts[:sort],
        filters: validated_opts[:filters],
        limit: validated_opts[:limit]
      }

      {:ok, command}
    else
      nil -> {:error, :required_user_id}
      error -> error
    end
  end

  defp validate_options(opts) do
    cursor = Keyword.get(opts, :cursor)
    user_id = Keyword.get(opts, :user_id)
    sort = Keyword.get(opts, :sort, @default_sort)
    filters = Keyword.get(opts, :filters, %{})

    limit =
      min(
        Keyword.get(opts, :limit, Integer.to_string(@default_limit)) |> String.to_integer(),
        @max_limit
      )

    with :ok <- validate_sort(sort),
         :ok <- validate_filters(filters),
         :ok <- validate_limit(limit) do
      {:ok, [cursor: cursor, sort: sort, filters: filters, limit: limit, user_id: user_id]}
    end
  end

  defp validate_sort(sort) when is_list(sort) and length(sort) > 0 do
    if Enum.all?(sort, &valid_sort_field?/1), do: :ok, else: {:error, :invalid_sort}
  end

  defp validate_sort(_), do: {:error, :invalid_sort}

  defp valid_sort_field?({field, direction}) when is_atom(field) and direction in [:asc, :desc],
    do: true

  defp valid_sort_field?(_), do: false

  defp validate_filters(filters) when is_map(filters), do: :ok
  defp validate_filters(_), do: {:error, :invalid_filters}

  defp validate_limit(limit) when is_integer(limit) and limit > 0 and limit <= @max_limit, do: :ok
  defp validate_limit(_), do: {:error, :invalid_limit}
end
