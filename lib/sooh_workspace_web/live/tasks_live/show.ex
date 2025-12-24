defmodule SoohWorkspaceWeb.TasksLive.Show do
  use SoohWorkspaceWeb, :live_view

  import SoohWorkspaceWeb.UIComponents
  alias SoohWorkspaceWeb.AppShell
  alias SoohWorkspace.Workspace
  alias SoohWorkspace.Workspace.Task

  @impl true
  def mount(%{"id" => id} = params, _session, socket) do
    task = Workspace.get_task!(id) |> Workspace.Repo.preload(milestone: [:project])

    # load current project for shell
    project = Workspace.get_project_with_details!(task.milestone.project_id)

    socket =
      socket
      |> assign(:page_title, "Task • SOOH")
      |> assign(:active, "tasks")
      |> assign(:current_project, project)
      |> assign(:task, task)
      |> assign(:edit_open, Map.get(params, "fix") == "done_means")
      |> assign(:task_form, to_form(Workspace.change_task(task), as: "task"))

    {:ok, socket}
  end

  @impl true
  def handle_event("global_search", %{"q" => q}, socket) do
    {:noreply,
     push_navigate(socket,
       to: ~p"/app/tasks?q=#{q}&project_id=#{socket.assigns.current_project.id}"
     )}
  end

  def handle_event("open_edit", _p, socket), do: {:noreply, assign(socket, :edit_open, true)}
  def handle_event("close_edit", _p, socket), do: {:noreply, assign(socket, :edit_open, false)}

  def handle_event("validate_task", %{"task" => params}, socket) do
    cs =
      socket.assigns.task
      |> Workspace.change_task(params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :task_form, to_form(cs, as: "task"))}
  end

  def handle_event("save_task", %{"task" => params}, socket) do
    params = normalize_tags(params)

    case Workspace.update_task(socket.assigns.task, params) do
      {:ok, t} ->
        t = Workspace.get_task!(t.id) |> Workspace.Repo.preload(milestone: [])

        {:noreply,
         socket
         |> assign(:task, t)
         |> assign(:edit_open, false)
         |> assign(:task_form, to_form(Workspace.change_task(t), as: "task"))
         |> put_flash(:info, "Task updated.")}

      {:error, cs} ->
        {:noreply, assign(socket, :task_form, to_form(cs, as: "task"))}
    end
  end

  def render(assigns) do
    t = assigns.task

    ~H"""
    <.live_component
      module={AppShell}
      id="app-shell"
      current_user={@current_user}
      current_project={@current_project}
      active={@active}
      search=""
      search_event="global_search"
      search_submit="global_search"
    >
      <div class="mb-6">
        <div class="text-xs uppercase tracking-wide text-slate-500">Task</div>
        <h1 class="mt-2 text-3xl font-semibold tracking-tight">{t.title}</h1>
        <.subtle class="mt-2 max-w-3xl">
          Milestone: <span class="font-medium text-slate-700">{t.milestone.title}</span>
        </.subtle>

        <div class="mt-5 flex flex-col sm:flex-row gap-3">
          <button
            class="inline-flex justify-center rounded-2xl bg-slate-900 text-white px-4 py-3 text-sm font-medium hover:bg-slate-800"
            phx-click="open_edit"
          >
            Edit task
          </button>
          <a
            href={~p"/app/tasks?project_id=#{@current_project.id}"}
            class="inline-flex justify-center rounded-2xl border border-slate-200 bg-white px-4 py-3 text-sm font-medium hover:bg-slate-50"
          >
            Back to tasks
          </a>
        </div>
      </div>

      <.card>
        <div class="text-xs uppercase tracking-wide text-slate-500">Definition</div>
        <div class="mt-2 text-sm text-slate-700">
          <span class="font-medium text-slate-800">Done means:</span>
          {t.done_means || "Missing. Add acceptance criteria."}
        </div>

        <div class="mt-4 flex flex-wrap gap-2">
          <%= for tag <- (t.tags || []) do %>
            <.pill>{tag}</.pill>
          <% end %>
        </div>
      </.card>

      <%= if @edit_open do %>
        <.modal title="Edit task" close_event="close_edit">
          <.form for={@task_form} phx-change="validate_task" phx-submit="save_task" class="space-y-3">
            <div>
              <label class="text-xs uppercase tracking-wide text-slate-500">Title</label>
              <input
                name="task[title]"
                value={t.title}
                class="mt-1 w-full rounded-2xl border border-slate-200 px-3 py-2 text-sm focus:ring-2 focus:ring-slate-400"
              />
            </div>

            <div>
              <label class="text-xs uppercase tracking-wide text-slate-500">Done means</label>
              <textarea
                name="task[done_means]"
                rows="3"
                class="mt-1 w-full rounded-2xl border border-slate-200 px-3 py-2 text-sm focus:ring-2 focus:ring-slate-400"
              ><%= t.done_means %></textarea>
            </div>

            <div class="grid grid-cols-1 sm:grid-cols-2 gap-3">
              <div>
                <label class="text-xs uppercase tracking-wide text-slate-500">
                  Tags (comma-separated)
                </label>
                <input
                  name="task[tags]"
                  value={Enum.join(t.tags || [], ", ")}
                  class="mt-1 w-full rounded-2xl border border-slate-200 px-3 py-2 text-sm focus:ring-2 focus:ring-slate-400"
                />
              </div>
              <div>
                <label class="text-xs uppercase tracking-wide text-slate-500">Due on</label>
                <input
                  type="date"
                  name="task[due_on]"
                  value={t.due_on}
                  class="mt-1 w-full rounded-2xl border border-slate-200 px-3 py-2 text-sm focus:ring-2 focus:ring-slate-400"
                />
              </div>
            </div>

            <div class="pt-2 flex gap-3">
              <button class="rounded-2xl bg-slate-900 text-white px-4 py-2 text-sm hover:bg-slate-800">
                Save
              </button>
              <button
                type="button"
                class="rounded-2xl border border-slate-200 bg-white px-4 py-2 text-sm hover:bg-slate-50"
                phx-click="close_edit"
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

  defp normalize_tags(params) do
    case params["tags"] do
      nil ->
        params

      tags when is_list(tags) ->
        params

      tags when is_binary(tags) ->
        parsed =
          tags
          |> String.split(",")
          |> Enum.map(&String.trim/1)
          |> Enum.reject(&(&1 == ""))

        Map.put(params, "tags", parsed)
    end
  end

  # inline modal used above
  attr :title, :string, required: true
  attr :close_event, :string, required: true
  slot :inner_block, required: true

  def modal(assigns) do
    ~H"""
    <div
      class="fixed inset-0 z-50 flex items-center justify-center p-4"
      role="dialog"
      aria-modal="true"
    >
      <div class="absolute inset-0 bg-slate-900/20" phx-click={@close_event} aria-hidden="true"></div>
      <div class="relative w-full max-w-2xl bg-white border border-slate-200 rounded-2xl p-5">
        <div class="flex items-start justify-between gap-3">
          <div>
            <div class="text-xs uppercase tracking-wide text-slate-500">Modal</div>
            <div class="mt-1 font-semibold">{@title}</div>
          </div>
          <button
            class="rounded-xl border border-slate-200 px-3 py-2 text-sm"
            phx-click={@close_event}
          >
            Close
          </button>
        </div>
        <div class="mt-4">{render_slot(@inner_block)}</div>
      </div>
    </div>
    """
  end
end
