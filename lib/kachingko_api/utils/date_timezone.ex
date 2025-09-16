defmodule KachingkoApi.Utils.DateTimezone do
  @manila "Asia/Manila"

  # assumes all bank uses manila timezone
  def from_pdf(naive_datetime_iso8601) when is_binary(naive_datetime_iso8601) do
    naive_datetime_iso8601
    |> NaiveDateTime.from_iso8601!()
    |> DateTime.from_naive!(@manila)
    |> DateTime.shift_zone!("Etc/UTC")
  end

  def from_mnl_to_utc(%Date{} = date) do
    date
    |> DateTime.new(~T[00:00:00], @manila)
    |> then(fn {:ok, dt} -> dt end)
    |> DateTime.shift_zone!("Etc/UTC")
    |> DateTime.to_date()
  end

  def from_utc_to_mnl(utc_iso8601) when is_binary(utc_iso8601) do
    utc_iso8601
    |> Date.from_iso8601!()
    |> DateTime.new!(~T[00:00:00], "Etc/UTC")
    |> DateTime.shift_zone!(@manila)
    |> DateTime.to_date()
    |> Date.to_iso8601()
  end
end
