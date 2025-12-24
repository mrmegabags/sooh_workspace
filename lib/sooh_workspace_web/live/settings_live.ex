defmodule SoohWorkspaceWeb.SettingsLive do
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

    socket =
      socket
      |> assign(:page_title, "Settings • SOOH")
      |> assign(:active, "settings")
      |> assign(:current_project, project)

    {:ok, socket}
  end

  @impl true
  def handle_event("global_search", %{"q" => q}, socket) do
    {:noreply,
     push_navigate(socket,
       to: ~p"/app/tasks?q=#{q}&project_id=#{socket.assigns.current_project.id}"
     )}
  end

  def render(assigns) do
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
        <div class="text-xs uppercase tracking-wide text-slate-500">Settings</div>
        <h1 class="mt-2 text-3xl font-semibold tracking-tight">Workspace controls.</h1>
        <.subtle class="mt-2 max-w-3xl">
          Keep settings minimal. Prefer defaults. Avoid configuration sprawl.
        </.subtle>
      </div>

      <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <.card>
          <div class="text-xs uppercase tracking-wide text-slate-500">Workspace profile</div>
          <div class="mt-2 font-semibold">SOOH Workspace</div>
          <.subtle class="mt-2">
            Tagline: Simple • Orderly • Organized • Harmonized (SOOH).
          </.subtle>

          <div class="mt-4 rounded-2xl border border-slate-200 bg-slate-50 p-4">
            <div class="text-sm font-medium">Planned</div>
            <.subtle class="mt-1">
              Multi-workspace support, branding overrides, and per-project membership controls.
            </.subtle>
          </div>
        </.card>

        <.card>
          <div class="text-xs uppercase tracking-wide text-slate-500">Roles</div>
          <div class="mt-2 font-semibold">Simple role set</div>
          <.subtle class="mt-2">
            Keep roles few and explicit: Owner, Contributor, Viewer. Expand only when necessary.
          </.subtle>

          <div class="mt-4 rounded-2xl border border-slate-200 bg-slate-50 p-4">
            <div class="text-sm font-medium">Planned</div>
            <.subtle class="mt-1">
              Role-based permissions for CRUD and snapshot publishing, scoped by project membership.
            </.subtle>
          </div>
        </.card>

        <.card class="lg:col-span-2">
          <div class="text-xs uppercase tracking-wide text-slate-500">Integrations</div>
          <div class="mt-2 font-semibold">Keep integrations lightweight.</div>
          <.subtle class="mt-2">
            Prefer low-latency, low-noise integrations: email invites, calendar reminders, and export.
          </.subtle>

          <div class="mt-4 grid grid-cols-1 sm:grid-cols-3 gap-4">
            <div class="rounded-2xl border border-slate-200 bg-white p-4">
              <div class="font-medium">Email</div>
              <.subtle class="mt-1">Invites and snapshot links.</.subtle>
            </div>
            <div class="rounded-2xl border border-slate-200 bg-white p-4">
              <div class="font-medium">Calendar</div>
              <.subtle class="mt-1">Milestone due reminders.</.subtle>
            </div>
            <div class="rounded-2xl border border-slate-200 bg-white p-4">
              <div class="font-medium">Export</div>
              <.subtle class="mt-1">Snapshot PDF/JSON for stakeholders.</.subtle>
            </div>
          </div>
        </.card>
      </div>
    </.live_component>
    """
  end
end
