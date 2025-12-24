defmodule SoohWorkspace.Workspace.Snapshot do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "snapshots" do
    belongs_to :project, SoohWorkspace.Workspace.Project

    field :token, :string
    field :password_hash, :string
    field :payload, :map
    field :clarity_score, :integer, default: 0

    timestamps()
  end

  def changeset(s, attrs) do
    s
    |> cast(attrs, [:project_id, :token, :password_hash, :payload, :clarity_score])
    |> validate_required([:project_id, :token, :payload, :clarity_score])
  end
end
