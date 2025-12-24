defmodule SoohWorkspaceWeb.ErrorJSONTest do
  use SoohWorkspaceWeb.ConnCase, async: true

  test "renders 404" do
    assert SoohWorkspaceWeb.ErrorJSON.render("404.json", %{}) == %{errors: %{detail: "Not Found"}}
  end

  test "renders 500" do
    assert SoohWorkspaceWeb.ErrorJSON.render("500.json", %{}) ==
             %{errors: %{detail: "Internal Server Error"}}
  end
end
