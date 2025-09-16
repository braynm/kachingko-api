defmodule KachingkoApi.Shared.Pagination.Metadata do
  @enforce_keys [:limit]
  defstruct [
    :next_cursor,
    :previous_cursor,
    :limit,
    :has_more,
    :has_previous,
    :total_count
  ]

  @type t :: %__MODULE__{
          next_cursor: String.t() | nil,
          previous_cursor: String.t() | nil,
          limit: pos_integer(),
          has_more: boolean(),
          has_previous: boolean(),
          total_count: pos_integer() | nil
        }

  alias KachingkoApi.Shared.Pagination.Cursor

  def new(records, limit, sort_fields, opts \\ []) do
    {entries, has_more} =
      if length(records) > limit do
        {Enum.take(records, limit), true}
      else
        {records, false}
      end

    next_cursor =
      case {List.last(entries), has_more} do
        {nil, _} -> nil
        {_, false} -> nil
        {last_record, true} -> Cursor.encode(last_record, sort_fields)
      end

    %__MODULE__{
      next_cursor: next_cursor,
      previous_cursor: Keyword.get(opts, :previous_cursor),
      limit: limit,
      has_more: has_more,
      has_previous: Keyword.get(opts, :has_previous, false),
      total_count: Keyword.get(opts, :total_count)
    }
  end

  def to_map(%__MODULE__{} = metadata) do
    %{
      next_cursor: metadata.next_cursor,
      previous_cursor: metadata.previous_cursor,
      limit: metadata.limit,
      has_more: metadata.has_more,
      has_previous: metadata.has_previous,
      total_count: metadata.total_count
    }
  end
end
