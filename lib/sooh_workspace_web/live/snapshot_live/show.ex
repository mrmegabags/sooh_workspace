defmodule SoohWorkspaceWeb.SnapshotLive.Show do
  use SoohWorkspaceWeb, :live_view

  import SoohWorkspaceWeb.UIComponents
  alias SoohWorkspace.Workspace

  @impl true
  def mount(%{"token" => token}, _session, socket) do
    case Workspace.get_snapshot_by_token(token) do
      nil ->
        {:ok, socket |> put_flash(:error, "Snapshot not found.") |> redirect(to: ~p"/")}

      snap ->
        {:ok,
         socket
         |> assign(:page_title, "Snapshot • SOOH")
         |> assign(:snap, snap)
         |> assign(:needs_password, not is_nil(snap.password_hash))
         |> assign(:unlocked, is_nil(snap.password_hash))
         |> assign(:pw_error, false)}
    end
  end

  @impl true
  def handle_event("unlock", %{"password" => pw}, socket) do
    snap = socket.assigns.snap

    case Workspace.verify_snapshot_password(snap, pw) do
      {:ok, _} -> {:noreply, assign(socket, :unlocked, true) |> assign(:pw_error, false)}
      {:error, _} -> {:noreply, assign(socket, :pw_error, true)}
    end
  end

  def render(assigns) do
    payload = assigns.snap.payload
    project = payload["project"]

    ~H"""
    <div class="min-h-screen bg-slate-50">
      <header class="sticky top-0 z-20 bg-white/95 backdrop-blur border-b border-slate-200">
        <div class="mx-auto max-w-5xl px-4 sm:px-6 h-14 flex items-center gap-3">
          <div class="h-9 w-9 rounded-2xl border border-slate-200 bg-slate-50 flex items-center justify-center font-semibold">
            SOOH
          </div>
          <div class="min-w-0">
            <div class="text-sm font-semibold truncate">{project["name"]} — Snapshot</div>
            <div class="text-xs text-slate-600 truncate">Read-only • SOOH clarity included</div>
          </div>
        </div>
      </header>

      <main class="mx-auto max-w-5xl px-4 sm:px-6 py-8">
        <%= if @needs_password and not @unlocked do %>
          <.card class="max-w-md">
            <div class="text-xs uppercase tracking-wide text-slate-500">Protected snapshot</div>
            <div class="mt-1 font-semibold">Enter password to view.</div>
            <form class="mt-4 space-y-3" phx-submit="unlock">
              <input
                name="password"
                type="password"
                class="w-full rounded-2xl border border-slate-200 px-3 py-2 text-sm focus:ring-2 focus:ring-slate-400"
              />
              <%= if @pw_error do %>
                <div class="text-sm text-amber-700">Invalid password.</div>
              <% end %>
              <button class="rounded-2xl bg-slate-900 text-white px-4 py-2 text-sm hover:bg-slate-800">
                Unlock
              </button>
            </form>
          </.card>
        <% else %>
          <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
            <.card class="lg:col-span-2">
              <div class="text-xs uppercase tracking-wide text-slate-500">Project</div>
              <div class="mt-2 text-2xl font-semibold">{project["name"]}</div>
              <.subtle class="mt-2">{project["purpose"]}</.subtle>

              <div class="mt-4 flex flex-wrap gap-2">
                <.pill>Phase: {String.capitalize(project["phase"])}</.pill>
                <.pill intent="primary">SOOH</.pill>
                <.pill>Momentum: {project["momentum_percent"]}%</.pill>
              </div>

              <div class="mt-5">
                <div class="text-xs uppercase tracking-wide text-slate-500">Success criteria</div>
                <ul class="mt-2 text-sm text-slate-700 list-disc pl-5 space-y-1">
                  <%= for item <- (project["success_criteria"] || []) do %>
                    <li>{item}</li>
                  <% end %>
                </ul>
              </div>
            </.card>

            <.card>
              <div class="text-xs uppercase tracking-wide text-slate-500">SOOH clarity</div>
              <div class="mt-2 text-3xl font-semibold">{payload["sooh_check"]["score"]}</div>
              <.subtle class="mt-1">/ 100</.subtle>

              <div class="mt-4 space-y-2">
                <%= for issue <- Enum.take(payload["sooh_check"]["issues"], 5) do %>
                  <div class="rounded-2xl border border-slate-200 bg-slate-50 p-3">
                    <div class="text-sm font-medium">{issue["title"]}</div>
                    <div class="mt-1 text-sm text-slate-600">{issue["detail"]}</div>
                  </div>
                <% end %>
              </div>
            </.card>
          </div>

          <div class="mt-6 grid grid-cols-1 gap-6">
            <.card>
              <div class="text-xs uppercase tracking-wide text-slate-500">Milestones & tasks</div>
              <div class="mt-4 space-y-4">
                <%= for m <- payload["milestones"] do %>
                  <div class="rounded-2xl border border-slate-200 bg-white p-4">
                    <div class="flex items-start justify-between gap-3">
                      <div>
                        <div class="font-semibold">{m["title"]}</div>
                        <div class="mt-1 text-sm text-slate-600">{m["description"]}</div>
                        <div class="mt-3 flex flex-wrap gap-2">
                          <.pill>Phase: {String.capitalize(m["phase"])}</.pill>
                          <.pill>Owner: {m["owner"] || "Unassigned"}</.pill>
                        </div>
                      </div>
                    </div>

                    <div class="mt-4 space-y-2">
                      <%= for t <- m["tasks"] do %>
                        <div class="rounded-2xl border border-slate-200 bg-slate-50 p-3">
                          <div class="flex items-start justify-between gap-3">
                            <div class="font-medium">{t["title"]}</div>
                            <.pill>{if t["is_done"], do: "Done", else: "Open"}</.pill>
                          </div>
                          <div class="mt-1 text-sm text-slate-600">
                            <span class="font-medium text-slate-700">Done means:</span> {t[
                              "done_means"
                            ] || "—"}
                          </div>
                        </div>
                      <% end %>
                    </div>
                  </div>
                <% end %>
              </div>
            </.card>

            <.card>
              <div class="text-xs uppercase tracking-wide text-slate-500">Decisions</div>
              <div class="mt-4 space-y-2">
                <%= for d <- payload["decisions"] do %>
                  <div class="rounded-2xl border border-slate-200 bg-white p-4">
                    <div class="flex items-start justify-between gap-3">
                      <div class="min-w-0">
                        <div class="font-semibold truncate">{d["title"]}</div>
                        <div class="mt-1 text-sm text-slate-600">{d["impact_note"]}</div>
                      </div>
                      <.pill intent={if d["status"] == "open", do: "warn", else: "success"}>
                        {String.capitalize(d["status"])}
                      </.pill>
                    </div>
                  </div>
                <% end %>
              </div>
            </.card>
          </div>
        <% end %>
      </main>
    </div>
    """
  end
end
