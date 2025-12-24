defmodule SoohWorkspaceWeb.SnapshotLive.New do
  use SoohWorkspaceWeb, :live_view

  import SoohWorkspaceWeb.UIComponents
  alias SoohWorkspace.Workspace
  alias SoohWorkspaceWeb.AppShell

  @impl true
  def mount(_params, _session, socket) do
    project = hd(Workspace.list_projects()) |> Workspace.get_project_with_details!()

    socket =
      socket
      |> assign(:page_title, "Publish Snapshot • SOOH")
      |> assign(:active, "projects")
      |> assign(:current_project, project)
      |> assign(:password, "")
      |> assign(:result, nil)

    {:ok, socket}
  end

  @impl true
  def handle_event("publish", %{"password" => password}, socket) do
    opts = if String.trim(password) == "", do: [], else: [password: password]

    case Workspace.publish_snapshot(socket.assigns.current_project.id, opts) do
      {:ok, snap} ->
        {:noreply, assign(socket, :result, %{token: snap.token})}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Snapshot could not be published.")}
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
    >
      <div class="max-w-2xl">
        <div class="text-xs uppercase tracking-wide text-slate-500">Publish snapshot</div>
        <h1 class="mt-2 text-3xl font-semibold tracking-tight">
          Share a read-only project status page.
        </h1>
        <.subtle class="mt-2">
          Includes milestones, tasks, decision queue, and the SOOH clarity score. Use a password if needed.
        </.subtle>

        <.card class="mt-6">
          <form phx-submit="publish" class="space-y-3">
            <div>
              <label class="text-xs uppercase tracking-wide text-slate-500">Optional password</label>
              <input
                name="password"
                value={@password}
                type="password"
                class="mt-1 w-full rounded-2xl border border-slate-200 px-3 py-2 text-sm focus:ring-2 focus:ring-slate-400"
                placeholder="Leave blank for public link"
              />
            </div>

            <button class="rounded-2xl bg-slate-900 text-white px-4 py-2 text-sm hover:bg-slate-800">
              Publish Snapshot
            </button>
          </form>

          <%= if @result do %>
            <div class="mt-4 rounded-2xl border border-slate-200 bg-slate-50 p-4">
              <div class="font-semibold">Snapshot published</div>
              <.subtle class="mt-1">
                Open:
                <a class="underline" href={~p"/s/#{@result.token}"}>{~p"/s/#{@result.token}"}</a>
              </.subtle>
            </div>
          <% end %>
        </.card>
      </div>
    </.live_component>
    """
  end
end
