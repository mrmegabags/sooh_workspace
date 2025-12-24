defmodule SoohWorkspace.Workspace do
  @moduledoc "SOOH Workspace domain: projects, milestones, tasks, decisions, contributors, snapshots."

  import Ecto.Query, warn: false
  alias SoohWorkspace.Repo

  alias SoohWorkspace.Workspace.{Project, Milestone, Task, Decision, Contributor, Snapshot}
  alias SoohWorkspace.Workspace.SoohCheck

  # --- Projects ---
  def list_projects(opts \\ []) do
    phase = Keyword.get(opts, :phase)
    q = from p in Project, order_by: [desc: p.updated_at]

    q =
      if phase in ["creation", "running", "exit"],
        do: from(p in q, where: p.phase == ^phase),
        else: q

    Repo.all(q)
  end

  def get_project!(id), do: Repo.get!(Project, id)

  def get_project_with_details!(id) do
    Project
    |> Repo.get!(id)
    |> Repo.preload(
      contributors: [],
      milestones: [:tasks, :owner],
      decisions: []
    )
  end

  def create_project(attrs), do: %Project{} |> Project.changeset(attrs) |> Repo.insert()
  def update_project(%Project{} = p, attrs), do: p |> Project.changeset(attrs) |> Repo.update()
  def delete_project(%Project{} = p), do: Repo.delete(p)

  # --- Contributors ---
  def list_contributors(project_id) do
    Repo.all(from c in Contributor, where: c.project_id == ^project_id, order_by: [asc: c.name])
  end

  def create_contributor(attrs),
    do: %Contributor{} |> Contributor.changeset(attrs) |> Repo.insert()

  def update_contributor(%Contributor{} = c, attrs),
    do: c |> Contributor.changeset(attrs) |> Repo.update()

  def get_contributor!(id), do: Repo.get!(Contributor, id)

  # --- Milestones ---
  def list_milestones(project_id, phase \\ nil) do
    q =
      from m in Milestone,
        where: m.project_id == ^project_id,
        order_by: [asc: m.due_on, asc: m.inserted_at],
        preload: [:tasks, :owner]

    if phase in ["creation", "running", "exit"],
      do: Repo.all(from m in q, where: m.phase == ^phase),
      else: Repo.all(q)
  end

  def create_milestone(attrs), do: %Milestone{} |> Milestone.changeset(attrs) |> Repo.insert()

  def update_milestone(%Milestone{} = m, attrs),
    do: m |> Milestone.changeset(attrs) |> Repo.update()

  def get_milestone!(id), do: Repo.get!(Milestone, id)

  # --- Tasks ---
  def list_tasks(project_id, search \\ nil) do
    q =
      from t in Task,
        join: m in assoc(t, :milestone),
        where: m.project_id == ^project_id,
        preload: [milestone: m],
        order_by: [asc: t.is_done, asc: t.due_on, desc: t.updated_at]

    q =
      if is_binary(search) and byte_size(String.trim(search)) > 0 do
        s = "%#{String.trim(search)}%"
        from [t, m] in q, where: ilike(t.title, ^s) or ilike(coalesce(t.done_means, ""), ^s)
      else
        q
      end

    Repo.all(q)
  end

  def create_task(attrs), do: %Task{} |> Task.changeset(attrs) |> Repo.insert()
  def update_task(%Task{} = t, attrs), do: t |> Task.changeset(attrs) |> Repo.update()
  def get_task!(id), do: Repo.get!(Task, id)

  # --- Decisions ---
  def list_decisions(project_id) do
    Repo.all(
      from d in Decision, where: d.project_id == ^project_id, order_by: [desc: d.inserted_at]
    )
  end

  def create_decision(attrs), do: %Decision{} |> Decision.changeset(attrs) |> Repo.insert()
  def update_decision(%Decision{} = d, attrs), do: d |> Decision.changeset(attrs) |> Repo.update()
  def get_decision!(id), do: Repo.get!(Decision, id)

  # --- SOOH Check ---
  def run_sooh_check(project_id) do
    project = get_project_with_details!(project_id)
    SoohCheck.run(project)
  end

  # --- Snapshot ---
  def publish_snapshot(project_id, opts \\ []) do
    project = get_project_with_details!(project_id)
    check = SoohCheck.run(project)

    token = Base.url_encode64(:crypto.strong_rand_bytes(16), padding: false)
    password = Keyword.get(opts, :password)

    payload = %{
      "project" => %{
        "id" => project.id,
        "name" => project.name,
        "phase" => project.phase,
        "momentum_percent" => project.momentum_percent,
        "purpose" => project.purpose,
        "success_criteria" => project.success_criteria,
        "constraints" => %{
          "budget" => project.constraints_budget,
          "time" => project.constraints_time,
          "scope" => project.constraints_scope
        },
        "exit_intent" => project.exit_intent,
        "narrative" => project.narrative
      },
      "milestones" =>
        Enum.map(project.milestones, fn m ->
          %{
            "id" => m.id,
            "phase" => m.phase,
            "title" => m.title,
            "description" => m.description,
            "owner" => (m.owner && m.owner.name) || nil,
            "due_on" => m.due_on,
            "tasks" =>
              Enum.map(m.tasks, fn t ->
                %{
                  "id" => t.id,
                  "title" => t.title,
                  "done_means" => t.done_means,
                  "tags" => t.tags,
                  "due_on" => t.due_on,
                  "is_done" => t.is_done
                }
              end)
          }
        end),
      "decisions" =>
        Enum.map(project.decisions, fn d ->
          %{
            "id" => d.id,
            "title" => d.title,
            "impact_note" => d.impact_note,
            "status" => d.status,
            "linked_success_criteria" => d.linked_success_criteria
          }
        end),
      "sooh_check" => %{
        "score" => check.score,
        "issues" => check.issues
      }
    }

    password_hash =
      if is_binary(password) and byte_size(String.trim(password)) > 0 do
        Bcrypt.hash_pwd_salt(password)
      else
        nil
      end

    %Snapshot{}
    |> Snapshot.changeset(%{
      project_id: project.id,
      token: token,
      password_hash: password_hash,
      payload: payload,
      clarity_score: check.score
    })
    |> Repo.insert()
  end

  def get_snapshot_by_token(token) do
    Repo.get_by(Snapshot, token: token)
  end

  def verify_snapshot_password(%Snapshot{password_hash: nil}, _pw), do: {:ok, :no_password}

  def verify_snapshot_password(%Snapshot{password_hash: hash}, pw) when is_binary(pw) do
    if Bcrypt.verify_pass(pw, hash), do: {:ok, :ok}, else: {:error, :invalid_password}
  end

  # --- Changesets for LiveView forms ---
  def change_project(%Project{} = p, attrs \\ %{}), do: Project.changeset(p, attrs)
  def change_contributor(%Contributor{} = c, attrs \\ %{}), do: Contributor.changeset(c, attrs)
  def change_milestone(%Milestone{} = m, attrs \\ %{}), do: Milestone.changeset(m, attrs)
  def change_task(%Task{} = t, attrs \\ %{}), do: Task.changeset(t, attrs)
  def change_decision(%Decision{} = d, attrs \\ %{}), do: Decision.changeset(d, attrs)
end
