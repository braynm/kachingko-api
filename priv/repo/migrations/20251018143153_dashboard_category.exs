defmodule KachingkoApi.Repo.Migrations.DashboardCategory do
  use Ecto.Migration

  def up do
    execute """
    DROP FUNCTION IF EXISTS kachingko_dashboard_category_chart;
    """

    execute read_sql_file("sql/sp_category_chart.sql")
  end

  def down do
    execute """
    DROP FUNCTION IF EXISTS kachingko_dashboard_category_chart;
    """
  end

  defp read_sql_file(filename) do
    sql_path = Path.join([Application.app_dir(:kachingko_api, "priv"), "repo", filename])
    File.read!(sql_path)
  end
end
