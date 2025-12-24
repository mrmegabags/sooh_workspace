defmodule SoohWorkspaceWeb.LiveHelpers do
  alias SoohWorkspace.Workspace

  # Pick current project:
  # - explicit project_id param wins
  # - otherwise most recently updated project
  def resolve_current_project(params) do
    case Map.get(params, "project_id") do
      nil ->
        Workspace.list_projects()
        |> List.first()

      id ->
        Workspace.get_project!(id)
    end
  end

  def ensure_project!(nil), do: raise("No projects available. Seed data is required.")
  def ensure_project!(p), do: p
end
