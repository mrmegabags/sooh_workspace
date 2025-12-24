defmodule SoohWorkspace.Workspace.Decision do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "decisions" do
    belongs_to :project, SoohWorkspace.Workspace.Project

    field :title, :string
    field :impact_note, :string
    field :status, :string, default: "open"
    field :linked_success_criteria, {:array, :string}, default: []

    timestamps()
  end

  def changeset(d, attrs) do
    d
    |> cast(attrs, [:project_id, :title, :impact_note, :status, :linked_success_criteria])
    |> validate_required([:project_id, :title, :status])
    |> validate_inclusion(:status, ["open", "closed"])
  end
end
