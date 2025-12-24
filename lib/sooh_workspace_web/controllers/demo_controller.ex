defmodule SoohWorkspaceWeb.DemoController do
  use SoohWorkspaceWeb, :controller

  alias SoohWorkspace.Accounts
  alias SoohWorkspaceWeb.UserAuth

  def create(conn, _params) do
    demo_email = "demo@sooh.local"

    case Accounts.get_user_by_email(demo_email) do
      nil ->
        conn
        |> put_flash(:error, "Demo user not configured.")
        |> redirect(to: ~p"/")

      user ->
        conn
        |> UserAuth.log_in_user(user)
        |> redirect(to: ~p"/app")
    end
  end
end
