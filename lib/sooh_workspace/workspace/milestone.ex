defmodule SoohWorkspace.Workspace.Milestone do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "milestones" do
    belongs_to :project, SoohWorkspace.Workspace.Project
    belongs_to :owner, SoohWorkspace.Workspace.Contributor, foreign_key: :owner_contributor_id

    field :phase, :string, default: "creation"
    field :title, :string
    field :description, :string
    field :due_on, :date

    has_many :tasks, SoohWorkspace.Workspace.Task

    timestamps()
  end

  def changeset(m, attrs) do
    m
    |> cast(attrs, [:project_id, :phase, :title, :description, :owner_contributor_id, :due_on])
    |> validate_required([:project_id, :phase, :title])
    |> validate_inclusion(:phase, ["creation", "running", "exit"])
  end
end
