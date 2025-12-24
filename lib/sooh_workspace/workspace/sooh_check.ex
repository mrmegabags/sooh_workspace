defmodule SoohWorkspace.Workspace.SoohCheck do
  @moduledoc """
  SOOH Check validations:
  - Every milestone has an owner
  - Every task has a “Done means”
  - Every decision is linked to success criteria
  Returns: score 0..100 and issue list with fix hints.
  """

  def run(project) do
    issues =
      []
      |> issues_milestones_owner(project)
      |> issues_tasks_done_means(project)
      |> issues_decisions_linked(project)

    score = score_from(project, issues)

    %{
      score: score,
      issues: issues,
      summary: summary(score, issues)
    }
  end

  defp issues_milestones_owner(acc, project) do
    missing =
      Enum.filter(project.milestones, fn m ->
        is_nil(m.owner_contributor_id)
      end)

    Enum.reduce(missing, acc, fn m, a ->
      [
        %{
          code: "milestone_missing_owner",
          title: "Milestone owner missing",
          detail: "“#{m.title}” has no owner. Assign one person to avoid diffuse ownership.",
          fix: %{action: "assign_owner", milestone_id: m.id}
        }
        | a
      ]
    end)
  end

  defp issues_tasks_done_means(acc, project) do
    tasks =
      project.milestones
      |> Enum.flat_map(&(&1.tasks || []))

    missing =
      Enum.filter(tasks, fn t ->
        dm = t.done_means || ""
        String.trim(dm) == ""
      end)

    Enum.reduce(missing, acc, fn t, a ->
      [
        %{
          code: "task_missing_done_means",
          title: "Task missing “Done means”",
          detail: "“#{t.title}” needs a clear acceptance definition to reduce rework.",
          fix: %{action: "edit_task_done_means", task_id: t.id}
        }
        | a
      ]
    end)
  end

  defp issues_decisions_linked(acc, project) do
    missing =
      Enum.filter(project.decisions, fn d ->
        d.status == "open" and (d.linked_success_criteria || []) == []
      end)

    Enum.reduce(missing, acc, fn d, a ->
      [
        %{
          code: "decision_not_linked",
          title: "Decision not linked to success criteria",
          detail: "“#{d.title}” should reference at least one success criterion.",
          fix: %{action: "link_decision", decision_id: d.id}
        }
        | a
      ]
    end)
  end

  defp score_from(project, issues) do
    # Weighting is intentionally simple and explainable.
    base = 100

    # Cap penalties to preserve interpretability.
    penalty =
      issues
      |> Enum.group_by(& &1.code)
      |> Enum.reduce(0, fn {code, items}, acc ->
        acc +
          case code do
            "milestone_missing_owner" -> min(length(items) * 10, 30)
            "task_missing_done_means" -> min(length(items) * 6, 40)
            "decision_not_linked" -> min(length(items) * 10, 30)
            _ -> 0
          end
      end)

    score = max(base - penalty, 0)

    # Mild bonus if project success criteria exist and at least one milestone exists.
    bonus =
      if (project.success_criteria || []) != [] and project.milestones != [], do: 3, else: 0

    min(score + bonus, 100)
  end

  defp summary(score, issues) do
    cond do
      score >= 90 -> "Clarity is strong. Keep definitions tight and ownership explicit."
      score >= 75 -> "Clarity is workable. Fix flagged items to avoid drift."
      true -> "Clarity is at risk. Resolve ownership, definitions of done, and decision linkage."
    end <>
      " Issues: #{length(issues)}."
  end
end
