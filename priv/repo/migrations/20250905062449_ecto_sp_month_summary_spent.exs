defmodule KachingkoApi.Repo.Migrations.EctoSpMonthSummarySpent do
  use Ecto.Migration

  def up do
    execute """
    DROP FUNCTION IF EXISTS kachingko_month_summary_spent;
    """

    execute read_sql_file("sql/sp_month_summary_spent.sql")
  end

  def down do
    execute """
    DROP FUNCTION IF EXISTS kachingko_month_summary_spent;
    """
  end

  # Helper function to read SQL files
  defp read_sql_file(filename) do
    sql_path = Path.join([Application.app_dir(:kachingko_api, "priv"), "repo", filename])
    File.read!(sql_path)
  end
end
