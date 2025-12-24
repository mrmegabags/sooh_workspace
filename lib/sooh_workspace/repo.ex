defmodule SoohWorkspace.Repo do
  use Ecto.Repo,
    otp_app: :sooh_workspace,
    adapter: Ecto.Adapters.Postgres
end
