defmodule SoohWorkspace.Workspace.Task do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "tasks" do
    belongs_to :milestone, SoohWorkspace.Workspace.Milestone

    field :title, :string
    field :done_means, :string
    field :tags, {:array, :string}, default: []
    field :due_on, :date
    field :is_done, :boolean, default: false

    timestamps()
  end

  def changeset(t, attrs) do
    t
    |> cast(attrs, [:milestone_id, :title, :done_means, :tags, :due_on, :is_done])
    |> validate_required([:milestone_id, :title])
  end
end
