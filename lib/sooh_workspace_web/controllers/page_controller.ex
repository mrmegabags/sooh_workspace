defmodule SoohWorkspaceWeb.PageController do
  use SoohWorkspaceWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
