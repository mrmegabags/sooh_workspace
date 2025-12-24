defmodule SoohWorkspaceWeb.TasksLive.Index do
  use SoohWorkspaceWeb, :live_view

  import SoohWorkspaceWeb.UIComponents
  alias SoohWorkspaceWeb.AppShell
  alias SoohWorkspaceWeb.LiveHelpers
  alias SoohWorkspace.Workspace

  @impl true
  def mount(params, _session, socket) do
    current =
      params
      |> LiveHelpers.resolve_current_project()
      |> LiveHelpers.ensure_project!()

    project = Workspace.get_project_with_details!(current.id)

    q = Map.get(params, "q", "")

    socket =
      socket
      |> assign(:page_title, "Tasks • SOOH")
      |> assign(:active, "tasks")
      |> assign(:current_project, project)
      |> assign(:search_q, q)
      |> assign(:tasks, Workspace.list_tasks(project.id, q))
      |> assign(:filter, Map.get(params, "filter", "open"))

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    q = Map.get(params, "q", socket.assigns.search_q)
    filter = Map.get(params, "filter", socket.assigns.filter)

    tasks =
      socket.assigns.current_project.id
      |> Workspace.list_tasks(q)
      |> apply_filter(filter)

    {:noreply, assign(socket, search_q: q, filter: filter, tasks: tasks)}
  end

  @impl true
  def handle_event("global_search", %{"q" => q}, socket) do
    {:noreply,
     push_patch(socket,
       to:
         ~p"/app/tasks?q=#{q}&filter=#{socket.assigns.filter}&project_id=#{socket.assigns.current_project.id}"
     )}
  end

  def handle_event("set_filter", %{"filter" => filter}, socket) do
    {:noreply,
     push_patch(socket,
       to:
         ~p"/app/tasks?q=#{socket.assigns.search_q}&filter=#{filter}&project_id=#{socket.assigns.current_project.id}"
     )}
  end

  def handle_event("toggle_task", %{"id" => id}, socket) do
    t = Workspace.get_task!(id)
    {:ok, _} = Workspace.update_task(t, %{is_done: not t.is_done})

    tasks =
      socket.assigns.current_project.id
      |> Workspace.list_tasks(socket.assigns.search_q)
      |> apply_filter(socket.assigns.filter)

    {:noreply, assign(socket, :tasks, tasks)}
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
        <div class="text-xs uppercase tracking-wide text-slate-500">Tasks</div>
        <h1 class="mt-2 text-3xl font-semibold tracking-tight">Definition-driven execution.</h1>
        <.subtle class="mt-2 max-w-3xl">
          Every task should state “Done means.” If it is ambiguous, it is rework.
        </.subtle>
      </div>

      <div class="flex flex-wrap gap-2 mb-4">
        <button class={tab_btn(@filter == "open")} phx-click="set_filter" phx-value-filter="open">
          Open
        </button>
        <button class={tab_btn(@filter == "done")} phx-click="set_filter" phx-value-filter="done">
          Done
        </button>
        <button class={tab_btn(@filter == "all")} phx-click="set_filter" phx-value-filter="all">
          All
        </button>
      </div>

      <.card>
        <div class="flex items-start justify-between gap-3">
          <div>
            <div class="text-xs uppercase tracking-wide text-slate-500">Task list</div>
            <div class="mt-1 font-semibold">{length(@tasks)} items</div>
          </div>
          <a
            href={~p"/app/projects/#{@current_project.id}"}
            class="rounded-2xl border border-slate-200 bg-white px-3 py-2 text-sm hover:bg-slate-50"
          >
            Manage milestones
          </a>
        </div>

        <div class="mt-4 space-y-2">
          <%= for t <- @tasks do %>
            <div class="rounded-2xl border border-slate-200 bg-white p-4">
              <div class="flex items-start gap-3">
                <button
                  class={toggle_btn(t.is_done)}
                  phx-click="toggle_task"
                  phx-value-id={t.id}
                  aria-label={"Toggle task #{t.title}"}
                >
                  {if t.is_done, do: "Done", else: "Open"}
                </button>

                <div class="min-w-0 flex-1">
                  <div class="flex items-start justify-between gap-3">
                    <div class="font-semibold">{t.title}</div>
                    <a
                      class="underline text-slate-700 hover:text-slate-900"
                      href={~p"/app/tasks/#{t.id}"}
                    >
                      Open
                    </a>
                  </div>

                  <div class="mt-1 text-sm text-slate-600">
                    <span class="font-medium text-slate-700">Milestone:</span>
                    {t.milestone.title}
                  </div>

                  <div class="mt-2 text-sm text-slate-600">
                    <span class="font-medium text-slate-700">Done means:</span>
                    {t.done_means || "Missing. Fix to reduce churn."}
                    <%= if is_nil(t.done_means) or String.trim(t.done_means) == "" do %>
                      <a
                        class="ml-2 underline text-slate-700 hover:text-slate-900"
                        href={~p"/app/tasks/#{t.id}?fix=done_means"}
                      >
                        Fix
                      </a>
                    <% end %>
                  </div>

                  <div class="mt-2 flex flex-wrap gap-2">
                    <%= for tag <- (t.tags || []) do %>
                      <.pill>{tag}</.pill>
                    <% end %>
                  </div>
                </div>
              </div>
            </div>
          <% end %>
        </div>
      </.card>
    </.live_component>
    """
  end

  defp apply_filter(tasks, "open"), do: Enum.filter(tasks, &(!&1.is_done))
  defp apply_filter(tasks, "done"), do: Enum.filter(tasks, & &1.is_done)
  defp apply_filter(tasks, _), do: tasks

  defp tab_btn(true), do: "rounded-2xl bg-slate-900 text-white px-3 py-2 text-sm"

  defp tab_btn(false),
    do: "rounded-2xl border border-slate-200 bg-white px-3 py-2 text-sm hover:bg-slate-50"

  defp toggle_btn(true),
    do: "rounded-2xl border border-slate-200 bg-white px-3 py-1.5 text-xs hover:bg-slate-50"

  defp toggle_btn(false),
    do: "rounded-2xl bg-slate-900 text-white px-3 py-1.5 text-xs hover:bg-slate-800"
end
