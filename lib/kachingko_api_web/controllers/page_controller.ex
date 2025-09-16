defmodule KachingkoApiWeb.PageController do
  use KachingkoApiWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
