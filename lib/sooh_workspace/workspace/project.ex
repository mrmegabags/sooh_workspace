defmodule SoohWorkspace.Workspace.Project do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "projects" do
    field :name, :string
    field :phase, :string, default: "creation"
    field :sooh_badge, :string, default: "SOOH"
    field :momentum_percent, :integer, default: 42

    field :purpose, :string
    field :success_criteria, {:array, :string}, default: []
    field :constraints_budget, :string
    field :constraints_time, :string
    field :constraints_scope, :string
    field :exit_intent, :string
    field :narrative, :string

    has_many :contributors, SoohWorkspace.Workspace.Contributor
    has_many :milestones, SoohWorkspace.Workspace.Milestone
    has_many :decisions, SoohWorkspace.Workspace.Decision
    has_many :snapshots, SoohWorkspace.Workspace.Snapshot

    timestamps()
  end

  def changeset(project, attrs) do
    project
    |> cast(attrs, [
      :name,
      :phase,
      :sooh_badge,
      :momentum_percent,
      :purpose,
      :success_criteria,
      :constraints_budget,
      :constraints_time,
      :constraints_scope,
      :exit_intent,
      :narrative
    ])
    |> validate_required([:name, :phase])
    |> validate_inclusion(:phase, ["creation", "running", "exit"])
    |> validate_number(:momentum_percent, greater_than_or_equal_to: 0, less_than_or_equal_to: 100)
  end
end
