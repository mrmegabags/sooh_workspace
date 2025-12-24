defmodule SoohWorkspace.Repo.Migrations.CreateWorkspaceTables do
  use Ecto.Migration

  def change do
    create table(:projects, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false
      # creation|running|exit
      add :phase, :string, null: false, default: "creation"
      add :sooh_badge, :string, null: false, default: "SOOH"
      add :momentum_percent, :integer, null: false, default: 42

      add :purpose, :text
      add :success_criteria, {:array, :text}, default: []
      add :constraints_budget, :string
      add :constraints_time, :string
      add :constraints_scope, :string
      add :exit_intent, :text
      add :narrative, :text

      timestamps()
    end

    create index(:projects, [:phase])
    create index(:projects, [:name])

    create table(:contributors, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :project_id, references(:projects, type: :binary_id, on_delete: :delete_all),
        null: false

      add :name, :string, null: false
      add :role, :string, null: false
      # available|pending|part_time
      add :availability, :string, null: false, default: "available"
      add :skills, {:array, :text}, default: []
      add :scope_note, :text

      timestamps()
    end

    create index(:contributors, [:project_id])
    create index(:contributors, [:role])

    create table(:milestones, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :project_id, references(:projects, type: :binary_id, on_delete: :delete_all),
        null: false

      add :phase, :string, null: false, default: "creation"
      add :title, :string, null: false
      add :description, :text

      add :owner_contributor_id,
          references(:contributors, type: :binary_id, on_delete: :nilify_all)

      add :due_on, :date

      timestamps()
    end

    create index(:milestones, [:project_id])
    create index(:milestones, [:phase])
    create index(:milestones, [:due_on])

    create table(:tasks, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :milestone_id, references(:milestones, type: :binary_id, on_delete: :delete_all),
        null: false

      add :title, :string, null: false
      add :done_means, :text
      add :tags, {:array, :text}, default: []
      add :due_on, :date
      add :is_done, :boolean, default: false, null: false

      timestamps()
    end

    create index(:tasks, [:milestone_id])
    create index(:tasks, [:due_on])
    create index(:tasks, [:is_done])

    create table(:decisions, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :project_id, references(:projects, type: :binary_id, on_delete: :delete_all),
        null: false

      add :title, :string, null: false
      add :impact_note, :text
      # open|closed
      add :status, :string, null: false, default: "open"
      add :linked_success_criteria, {:array, :text}, default: []

      timestamps()
    end

    create index(:decisions, [:project_id])
    create index(:decisions, [:status])

    create table(:snapshots, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :project_id, references(:projects, type: :binary_id, on_delete: :delete_all),
        null: false

      add :token, :string, null: false
      add :password_hash, :string
      add :payload, :map, null: false
      add :clarity_score, :integer, null: false, default: 0

      timestamps()
    end

    create unique_index(:snapshots, [:token])
    create index(:snapshots, [:project_id])
  end
end
