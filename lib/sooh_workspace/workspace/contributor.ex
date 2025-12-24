defmodule SoohWorkspace.Workspace.Contributor do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "contributors" do
    belongs_to :project, SoohWorkspace.Workspace.Project

    field :name, :string
    field :role, :string
    field :availability, :string, default: "available"
    field :skills, {:array, :string}, default: []
    field :scope_note, :string

    timestamps()
  end

  def changeset(c, attrs) do
    c
    |> cast(attrs, [:project_id, :name, :role, :availability, :skills, :scope_note])
    |> validate_required([:project_id, :name, :role, :availability])
    |> validate_inclusion(:availability, ["available", "pending", "part_time"])
  end
end
