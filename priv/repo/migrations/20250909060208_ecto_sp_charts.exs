defmodule KachingkoApi.Repo.Migrations.EctoSpCharts do
  use Ecto.Migration

  def up do
    execute """
    DROP FUNCTION IF EXISTS kachingko_totals;
    """

    execute read_sql_file("sql/sp_charts.sql")
  end

  def down do
    execute """
    DROP FUNCTION IF EXISTS kachingko_totals;
    """
  end

  defp read_sql_file(filename) do
    sql_path = Path.join([Application.app_dir(:kachingko_api, "priv"), "repo", filename])
    File.read!(sql_path)
  end
end
