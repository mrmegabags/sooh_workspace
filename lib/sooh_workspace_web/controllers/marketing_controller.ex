defmodule SoohWorkspaceWeb.MarketingController do
  use SoohWorkspaceWeb, :controller

  def home(conn, _params) do
    render(conn, :home, page_title: "SOOH Workspace")
  end

  def product(conn, _params), do: render(conn, :product, page_title: "Product • SOOH")
  def pricing(conn, _params), do: render(conn, :pricing, page_title: "Pricing • SOOH")
  def about(conn, _params), do: render(conn, :about, page_title: "About • SOOH")
  def docs(conn, _params), do: render(conn, :docs, page_title: "Docs • SOOH")
  def privacy(conn, _params), do: render(conn, :privacy, page_title: "Privacy • SOOH")
  def support(conn, _params), do: render(conn, :support, page_title: "Support • SOOH")
end
