defmodule SoohWorkspaceWeb.ProjectsLive.Index do
  use SoohWorkspaceWeb, :live_view

  import SoohWorkspaceWeb.UIComponents
  alias SoohWorkspaceWeb.AppShell
  alias SoohWorkspaceWeb.LiveHelpers
  alias SoohWorkspace.Workspace
  alias SoohWorkspace.Workspace.Project

  @impl true
  def mount(params, _session, socket) do
    current =
      params
      |> LiveHelpers.resolve_current_project()
      |> LiveHelpers.ensure_project!()

    socket =
      socket
      |> assign(:page_title, "Projects • SOOH")
      |> assign(:active, "projects")
      |> assign(:phase, Map.get(params, "phase", "all"))
      |> assign(:search_q, Map.get(params, "q", ""))
      |> assign(:current_project, Workspace.get_project_with_details!(current.id))
      |> assign(:projects, list_projects(socket.assigns.phase, socket.assigns.search_q))
      |> assign(:create_open, false)
      |> assign(:project_form, to_form(Workspace.change_project(%Project{}), as: "project"))

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    phase = Map.get(params, "phase", socket.assigns.phase)
    q = Map.get(params, "q", socket.assigns.search_q)

    {:noreply,
     socket
     |> assign(:phase, phase)
     |> assign(:search_q, q)
     |> assign(:projects, list_projects(phase, q))}
  end

  @impl true
  def handle_event("global_search", %{"q" => q}, socket) do
    {:noreply, push_patch(socket, to: ~p"/app/projects?q=#{q}&phase=#{socket.assigns.phase}")}
  end

  def handle_event("set_phase", %{"phase" => phase}, socket) do
    {:noreply,
     push_patch(socket, to: ~p"/app/projects?phase=#{phase}&q=#{socket.assigns.search_q}")}
  end

  def handle_event("open_create", _params, socket),
    do: {:noreply, assign(socket, :create_open, true)}

  def handle_event("close_create", _params, socket),
    do: {:noreply, assign(socket, :create_open, false)}

  def handle_event("validate_project", %{"project" => params}, socket) do
    changeset =
      %Project{}
      |> Workspace.change_project(params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :project_form, to_form(changeset, as: "project"))}
  end

  def handle_event("create_project", %{"project" => params}, socket) do
    case Workspace.create_project(params) do
      {:ok, p} ->
        {:noreply,
         socket
         |> put_flash(:info, "Project created.")
         |> assign(:create_open, false)
         |> push_navigate(to: ~p"/app/projects/#{p.id}")}

      {:error, cs} ->
        {:noreply, assign(socket, :project_form, to_form(cs, as: "project"))}
    end
  end

  def render(assigns) do
    ~H"""
    <.live_component
      module={AppShell}
      id="app-shell"
      current_user={@current_user}
      current_project={@current_project}
      active={@active}
      search={@search_q}
      search_event="global_search"
      search_submit="global_search"
    >
      <div class="mb-6">
        <div class="text-xs uppercase tracking-wide text-slate-500">Projects</div>
        <h1 class="mt-2 text-3xl font-semibold tracking-tight">Keep the portfolio readable.</h1>
        <.subtle class="mt-2 max-w-3xl">
          Projects are phase-scoped: Creation → Running → Exit. Keep names short and outcomes explicit.
        </.subtle>

        <div class="mt-5 flex flex-col sm:flex-row gap-3">
          <button
            class="inline-flex justify-center rounded-2xl bg-slate-900 text-white px-4 py-3 text-sm font-medium hover:bg-slate-800"
            phx-click="open_create"
          >
            Create project
          </button>
          <a
            href={~p"/app"}
            class="inline-flex justify-center rounded-2xl border border-slate-200 bg-white px-4 py-3 text-sm font-medium hover:bg-slate-50"
          >
            Back to dashboard
          </a>
        </div>
      </div>

      <div class="flex flex-wrap gap-2 mb-4">
        <button class={tab_btn(@phase == "all")} phx-click="set_phase" phx-value-phase="all">
          All
        </button>
        <button class={tab_btn(@phase == "creation")} phx-click="set_phase" phx-value-phase="creation">
          Creation
        </button>
        <button class={tab_btn(@phase == "running")} phx-click="set_phase" phx-value-phase="running">
          Running
        </button>
        <button class={tab_btn(@phase == "exit")} phx-click="set_phase" phx-value-phase="exit">
          Exit
        </button>
      </div>

      <.card>
        <div class="flex items-start justify-between gap-3">
          <div>
            <div class="text-xs uppercase tracking-wide text-slate-500">Project list</div>
            <div class="mt-1 font-semibold">{length(@projects)} items</div>
          </div>
        </div>

        <div class="mt-4 overflow-x-auto">
          <table class="min-w-full text-sm">
            <thead class="text-xs uppercase tracking-wide text-slate-500">
              <tr class="border-b border-slate-200">
                <th class="text-left py-2 pr-4">Name</th>
                <th class="text-left py-2 pr-4">Phase</th>
                <th class="text-left py-2 pr-4">Momentum</th>
                <th class="text-right py-2">Open</th>
              </tr>
            </thead>
            <tbody>
              <%= for p <- @projects do %>
                <tr class="border-b border-slate-100">
                  <td class="py-3 pr-4 font-medium">{p.name}</td>
                  <td class="py-3 pr-4">
                    <.pill>{String.capitalize(p.phase)}</.pill>
                  </td>
                  <td class="py-3 pr-4 w-56">
                    <div class="flex items-center gap-3">
                      <div class="w-36"><.progress value={p.momentum_percent} /></div>
                      <div class="text-xs text-slate-600">{p.momentum_percent}%</div>
                    </div>
                  </td>
                  <td class="py-3 text-right">
                    <a
                      class="underline text-slate-700 hover:text-slate-900"
                      href={~p"/app/projects/#{p.id}"}
                    >
                      Open
                    </a>
                  </td>
                </tr>
              <% end %>
            </tbody>
          </table>
        </div>
      </.card>

      <%= if @create_open do %>
        <.modal title="Create project" close_event="close_create">
          <.form
            for={@project_form}
            phx-change="validate_project"
            phx-submit="create_project"
            class="space-y-3"
          >
            <div>
              <label class="text-xs uppercase tracking-wide text-slate-500">Name</label>
              <input
                name="project[name]"
                class="mt-1 w-full rounded-2xl border border-slate-200 px-3 py-2 text-sm focus:ring-2 focus:ring-slate-400"
              />
              <%= for err <- Keyword.get_values(@project_form.errors, :name) do %>
                <div class="text-xs text-amber-700 mt-1">{err}</div>
              <% end %>
            </div>

            <div>
              <label class="text-xs uppercase tracking-wide text-slate-500">Phase</label>
              <select
                name="project[phase]"
                class="mt-1 w-full rounded-2xl border border-slate-200 px-3 py-2 text-sm focus:ring-2 focus:ring-slate-400"
              >
                <option value="creation">Creation</option>
                <option value="running">Running</option>
                <option value="exit">Exit</option>
              </select>
            </div>

            <div>
              <label class="text-xs uppercase tracking-wide text-slate-500">Momentum (0–100)</label>
              <input
                name="project[momentum_percent]"
                type="number"
                min="0"
                max="100"
                class="mt-1 w-full rounded-2xl border border-slate-200 px-3 py-2 text-sm focus:ring-2 focus:ring-slate-400"
                value="35"
              />
            </div>

            <div class="pt-2 flex gap-3">
              <button class="rounded-2xl bg-slate-900 text-white px-4 py-2 text-sm hover:bg-slate-800">
                Create
              </button>
              <button
                type="button"
                class="rounded-2xl border border-slate-200 bg-white px-4 py-2 text-sm hover:bg-slate-50"
                phx-click="close_create"
              >
                Cancel
              </button>
            </div>
          </.form>
        </.modal>
      <% end %>
    </.live_component>
    """
  end

  defp list_projects(phase, q) do
    projects =
      case phase do
        "creation" -> Workspace.list_projects(phase: "creation")
        "running" -> Workspace.list_projects(phase: "running")
        "exit" -> Workspace.list_projects(phase: "exit")
        _ -> Workspace.list_projects()
      end

    q = String.trim(q || "")

    if q == "" do
      projects
    else
      s = String.downcase(q)
      Enum.filter(projects, fn p -> String.contains?(String.downcase(p.name), s) end)
    end
  end

  defp tab_btn(true), do: "rounded-2xl bg-slate-900 text-white px-3 py-2 text-sm"

  defp tab_btn(false),
    do: "rounded-2xl border border-slate-200 bg-white px-3 py-2 text-sm hover:bg-slate-50"

  # Minimal modal component for consistency:
  defp modal(assigns), do: SoohWorkspaceWeb.ProjectsLive.Index.modal(assigns)
end
