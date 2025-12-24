
defmodule SoohWorkspaceWeb.DashboardLive do
  use SoohWorkspaceWeb, :live_view

  import SoohWorkspaceWeb.UIComponents
  alias SoohWorkspace.Workspace
  alias SoohWorkspaceWeb.AppShell

  @impl true
  def mount(_params, _session, socket) do
    project = hd(Workspace.list_projects()) || seed_fallback_project()
    details = Workspace.get_project_with_details!(project.id)

    check = Workspace.run_sooh_check(details.id)

    socket =
      socket
      |> assign(:page_title, "Dashboard • SOOH")
      |> assign(:active, "dashboard")
      |> assign(:current_project, details)
      |> assign(:check, check)
      |> assign(:phase_tab, details.phase)
      |> assign(:idea_edit_open, false)
      |> assign(:idea_form, idea_form(details))
      |> assign(:role_filter, "all")

    {:ok, socket}
  end

  @impl true
  def handle_event("run_sooh_check", _params, socket) do
    check = Workspace.run_sooh_check(socket.assigns.current_project.id)
    {:noreply, assign(socket, :check, check)}
  end

  def handle_event("open_idea_edit", _params, socket) do
    {:noreply, assign(socket, :idea_edit_open, true)}
  end

  def handle_event("close_idea_edit", _params, socket) do
    {:noreply, assign(socket, :idea_edit_open, false)}
  end

  def handle_event("save_idea_canvas", %{"idea" => params}, socket) do
    p = socket.assigns.current_project

    success_criteria =
      (params["success_criteria"] || "")
      |> String.split("\n")
      |> Enum.map(&String.trim/1)
      |> Enum.reject(&(&1 == ""))

    attrs = %{
      purpose: params["purpose"],
      success_criteria: success_criteria,
      constraints_budget: params["constraints_budget"],
      constraints_time: params["constraints_time"],
      constraints_scope: params["constraints_scope"],
      exit_intent: params["exit_intent"],
      narrative: params["narrative"]
    }

    case Workspace.update_project(p, attrs) do
      {:ok, updated} ->
        updated = Workspace.get_project_with_details!(updated.id)
        {:noreply,
         socket
         |> assign(:current_project, updated)
         |> assign(:idea_edit_open, false)
         |> assign(:idea_form, idea_form(updated))
         |> assign(:check, Workspace.run_sooh_check(updated.id))}

      {:error, changeset} ->
        {:noreply, assign(socket, :idea_form, to_form(changeset, as: "idea"))}
    end
  end

  def handle_event("set_phase_tab", %{"phase" => phase}, socket) do
    {:noreply, assign(socket, :phase_tab, phase)}
  end

  def handle_event("set_role_filter", %{"role" => role}, socket) do
    {:noreply, assign(socket, :role_filter, role)}
  end

  @impl true
  def render(assigns) do
    p = assigns.current_project
    milestones = p.milestones |> Enum.filter(&(&1.phase == assigns.phase_tab))
    decisions_open = p.decisions |> Enum.filter(&(&1.status == "open"))

    contributors = p.contributors
    contributors =
      case assigns.role_filter do
        "all" -> contributors
        r -> Enum.filter(contributors, &(String.downcase(&1.role) == r))
      end

    active_projects = length(Workspace.list_projects())
    next_milestone = next_milestone(p.milestones)

    assigns =
      assigns
      |> assign(:milestones_for_tab, milestones)
      |> assign(:decisions_open, decisions_open)
      |> assign(:contributors_filtered, contributors)
      |> assign(:active_projects, active_projects)
      |> assign(:next_milestone, next_milestone)

    ~H"""
    <.live_component module={AppShell}
      id="app-shell"
      current_user={@current_user}
      current_project={@current_project}
      active={@active}>

      <!-- Header -->
      <div class="mb-6">
        <div class="text-xs uppercase tracking-wide text-slate-500">Dashboard</div>
        <h1 class="mt-2 text-3xl sm:text-4xl font-semibold tracking-tight">
          Communicate the big picture. Execute with harmony.
        </h1>
        <.subtle class="mt-2 max-w-3xl">
          One place to capture vision, design a clear pathway, coordinate professionals, and drive projects from creation to exit.
        </.subtle>

        <div class="mt-5 flex flex-col sm:flex-row gap-3">
          <a href={~p"/app/contributors"} class="inline-flex justify-center rounded-2xl border border-slate-200 bg-white px-4 py-3 text-sm font-medium hover:bg-slate-50">
            Invite contributor
          </a>
          <a href={~p"/app/projects"} class="inline-flex justify-center rounded-2xl bg-slate-900 text-white px-4 py-3 text-sm font-medium hover:bg-slate-800">
            Create project
          </a>
        </div>
      </div>

      <!-- KPI strip -->
      <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 mb-6">
        <.card>
          <.kpi label="Active projects">
            <%= @active_projects %>
          </.kpi>
          <.subtle class="mt-2">
            Creation: <%= count_projects("creation") %> • Running: <%= count_projects("running") %>
          </.subtle>
        </.card>

        <.card>
          <.kpi label="Next milestone">
            <%= @next_milestone.title %>
          </.kpi>
          <.subtle class="mt-2">
            Due <%= @next_milestone.due_label %>
          </.subtle>
        </.card>

        <.card>
          <.kpi label="Open decisions">
            <%= length(@decisions_open) %>
          </.kpi>
          <.subtle class="mt-2">
            Status: <.pill intent={if length(@decisions_open) > 0, do: "warn", else: "success"}><%= if length(@decisions_open) > 0, do: "Open", else: "Clear" %></.pill>
          </.subtle>
        </.card>

        <.card>
          <.kpi label="Contributor load">
            68%
          </.kpi>
          <.subtle class="mt-2">
            SOOH status: <.pill intent="primary">Balanced</.pill>
          </.subtle>
        </.card>
      </div>

      <!-- Two-column core -->
      <div class="grid grid-cols-1 lg:grid-cols-2 gap-6 mb-6">
        <!-- Idea Canvas -->
        <.card>
          <div class="flex items-start justify-between gap-3">
            <div>
              <div class="text-xs uppercase tracking-wide text-slate-500">Idea canvas</div>
              <div class="mt-1 font-semibold">Define success before velocity.</div>
            </div>
            <button class="rounded-2xl border border-slate-200 bg-white px-3 py-2 text-sm hover:bg-slate-50
                           focus:outline-none focus:ring-2 focus:ring-slate-400"
                    phx-click="open_idea_edit">
              Edit
            </button>
          </div>

          <div class="mt-4 space-y-4">
            <div>
              <div class="text-xs uppercase tracking-wide text-slate-500">Purpose</div>
              <div class="mt-1 text-sm leading-6"><%= p.purpose %></div>
            </div>

            <div>
              <div class="text-xs uppercase tracking-wide text-slate-500">Success criteria</div>
              <ul class="mt-2 text-sm text-slate-700 list-disc pl-5 space-y-1">
                <%= for item <- p.success_criteria do %>
                  <li><%= item %></li>
                <% end %>
              </ul>
            </div>

            <div class="grid grid-cols-1 sm:grid-cols-3 gap-3">
              <div class="rounded-2xl border border-slate-200 bg-slate-50 p-3">
                <div class="text-xs uppercase tracking-wide text-slate-500">Budget</div>
                <div class="mt-1 text-sm font-medium"><%= p.constraints_budget %></div>
              </div>
              <div class="rounded-2xl border border-slate-200 bg-slate-50 p-3">
                <div class="text-xs uppercase tracking-wide text-slate-500">Time</div>
                <div class="mt-1 text-sm font-medium"><%= p.constraints_time %></div>
              </div>
              <div class="rounded-2xl border border-slate-200 bg-slate-50 p-3">
                <div class="text-xs uppercase tracking-wide text-slate-500">Scope</div>
                <div class="mt-1 text-sm font-medium"><%= p.constraints_scope %></div>
              </div>
            </div>

            <div>
              <div class="text-xs uppercase tracking-wide text-slate-500">Exit intent</div>
              <div class="mt-1 text-sm leading-6"><%= p.exit_intent %></div>
            </div>

            <div class="rounded-2xl border border-slate-200 bg-white p-3 flex items-start justify-between gap-3">
              <div class="min-w-0">
                <div class="text-xs uppercase tracking-wide text-slate-500">One-line narrative</div>
                <div class="mt-1 text-sm font-medium"><%= p.narrative %></div>
              </div>
              <.pill intent="primary">SOOH</.pill>
            </div>
          </div>

          <%= if @idea_edit_open do %>
            <div class="fixed inset-0 z-50 flex items-center justify-center p-4" role="dialog" aria-modal="true">
              <div class="absolute inset-0 bg-slate-900/20" phx-click="close_idea_edit" aria-hidden="true"></div>
              <div class="relative w-full max-w-2xl bg-white border border-slate-200 rounded-2xl p-5">
                <div class="flex items-start justify-between gap-3">
                  <div>
                    <div class="text-xs uppercase tracking-wide text-slate-500">Edit</div>
                    <div class="mt-1 font-semibold">Idea Canvas</div>
                  </div>
                  <button class="rounded-xl border border-slate-200 px-3 py-2 text-sm" phx-click="close_idea_edit">Close</button>
                </div>

                <.form for={@idea_form} phx-submit="save_idea_canvas" class="mt-4 space-y-3">
                  <div>
                    <label class="text-xs uppercase tracking-wide text-slate-500">Purpose</label>
                    <textarea name="idea[purpose]" rows="2" class="mt-1 w-full rounded-2xl border border-slate-200 px-3 py-2 text-sm focus:ring-2 focus:ring-slate-400"><%= p.purpose %></textarea>
                  </div>

                  <div>
                    <label class="text-xs uppercase tracking-wide text-slate-500">Success criteria (one per line)</label>
                    <textarea name="idea[success_criteria]" rows="4" class="mt-1 w-full rounded-2xl border border-slate-200 px-3 py-2 text-sm focus:ring-2 focus:ring-slate-400"><%= Enum.join(p.success_criteria, "\n") %></textarea>
                  </div>

                  <div class="grid grid-cols-1 sm:grid-cols-3 gap-3">
                    <div>
                      <label class="text-xs uppercase tracking-wide text-slate-500">Budget</label>
                      <input name="idea[constraints_budget]" value={p.constraints_budget} class="mt-1 w-full rounded-2xl border border-slate-200 px-3 py-2 text-sm focus:ring-2 focus:ring-slate-400"/>
                    </div>
                    <div>
                      <label class="text-xs uppercase tracking-wide text-slate-500">Time</label>
                      <input name="idea[constraints_time]" value={p.constraints_time} class="mt-1 w-full rounded-2xl border border-slate-200 px-3 py-2 text-sm focus:ring-2 focus:ring-slate-400"/>
                    </div>
                    <div>
                      <label class="text-xs uppercase tracking-wide text-slate-500">Scope</label>
                      <input name="idea[constraints_scope]" value={p.constraints_scope} class="mt-1 w-full rounded-2xl border border-slate-200 px-3 py-2 text-sm focus:ring-2 focus:ring-slate-400"/>
                    </div>
                  </div>

                  <div>
                    <label class="text-xs uppercase tracking-wide text-slate-500">Exit intent</label>
                    <textarea name="idea[exit_intent]" rows="2" class="mt-1 w-full rounded-2xl border border-slate-200 px-3 py-2 text-sm focus:ring-2 focus:ring-slate-400"><%= p.exit_intent %></textarea>
                  </div>

                  <div>
                    <label class="text-xs uppercase tracking-wide text-slate-500">One-line narrative</label>
                    <input name="idea[narrative]" value={p.narrative} class="mt-1 w-full rounded-2xl border border-slate-200 px-3 py-2 text-sm focus:ring-2 focus:ring-slate-400"/>
                  </div>

                  <div class="pt-2 flex gap-3">
                    <button class="rounded-2xl bg-slate-900 text-white px-4 py-2 text-sm hover:bg-slate-800">Save</button>
                    <button type="button" class="rounded-2xl border border-slate-200 bg-white px-4 py-2 text-sm hover:bg-slate-50" phx-click="close_idea_edit">Cancel</button>
                  </div>
                </.form>
              </div>
            </div>
          <% end %>
        </.card>

        <!-- Execution Pathway -->
        <.card>
          <div class="flex items-start justify-between gap-3">
            <div>
              <div class="text-xs uppercase tracking-wide text-slate-500">Execution pathway</div>
              <div class="mt-1 font-semibold">Milestones, tasks, decisions—by phase.</div>
            </div>
            <a href={~p"/app/tasks"} class="rounded-2xl border border-slate-200 bg-white px-3 py-2 text-sm hover:bg-slate-50">
              Add task
            </a>
          </div>

          <!-- Tabs -->
          <div class="mt-4 flex gap-2">
            <button class={tab_class(@phase_tab == "creation")} phx-click="set_phase_tab" phx-value-phase="creation">Creation</button>
            <button class={tab_class(@phase_tab == "running")} phx-click="set_phase_tab" phx-value-phase="running">Running</button>
            <button class={tab_class(@phase_tab == "exit")} phx-click="set_phase_tab" phx-value-phase="exit">Exit</button>
          </div>

          <!-- Milestones -->
          <div class="mt-4 space-y-4">
            <%= for m <- @milestones_for_tab do %>
              <div class="rounded-2xl border border-slate-200 bg-white p-4">
                <div class="flex items-start justify-between gap-3">
                  <div class="min-w-0">
                    <div class="font-semibold truncate"><%= m.title %></div>
                    <.subtle class="mt-1"><%= m.description %></.subtle>
                    <div class="mt-3 flex flex-wrap gap-2">
                      <.pill>Owner: <%= (m.owner && m.owner.name) || "Unassigned" %></.pill>
                      <.pill>Due: <%= due_label(m.due_on) %></.pill>
                    </div>
                  </div>
                </div>

                <div class="mt-4 space-y-3">
                  <%= for t <- m.tasks do %>
                    <div class="flex items-start gap-3">
                      <input type="checkbox" checked={t.is_done} class="mt-1 h-4 w-4 rounded border-slate-300"
                             aria-label={"Mark task done: #{t.title}"} disabled />
                      <div class="min-w-0 flex-1">
                        <div class="flex items-start justify-between gap-3">
                          <div class="font-medium"><%= t.title %></div>
                          <div class="text-xs text-slate-600"><%= relative_due(t.due_on) %></div>
                        </div>
                        <div class="mt-1 text-sm text-slate-600">
                          <span class="font-medium text-slate-700">Done means:</span>
                          <%= t.done_means || "Define acceptance to reduce rework." %>
                        </div>
                        <div class="mt-2 flex flex-wrap gap-2">
                          <%= for tag <- t.tags do %>
                            <.pill><%= tag %></.pill>
                          <% end %>
                        </div>
                      </div>
                    </div>
                  <% end %>
                </div>
              </div>
            <% end %>
          </div>

          <!-- Decision queue -->
          <div class="mt-6 rounded-2xl border border-slate-200 bg-slate-50 p-4">
            <div class="flex items-start justify-between gap-3">
              <div>
                <div class="font-semibold">Decision queue</div>
                <.subtle class="mt-1">Open decisions should link to success criteria to prevent drift.</.subtle>
              </div>
              <a href={~p"/app/projects/#{@current_project.id}"} class="rounded-2xl border border-slate-200 bg-white px-3 py-2 text-sm hover:bg-slate-50">
                Add
              </a>
            </div>

            <div class="mt-4 space-y-2">
              <%= for d <- @decisions_open do %>
                <div class="rounded-2xl border border-slate-200 bg-white p-3">
                  <div class="flex items-start justify-between gap-3">
                    <div class="min-w-0">
                      <div class="font-medium truncate"><%= d.title %></div>
                      <div class="mt-1 text-sm text-slate-600"><%= d.impact_note %></div>
                    </div>
                    <.pill intent="warn">Open</.pill>
                  </div>
                </div>
              <% end %>
            </div>
          </div>
        </.card>
      </div>

      <!-- Contributors + SOOH Check (3-column) -->
      <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <!-- Contributors panel (2 cols wide) -->
        <.card class="lg:col-span-2">
          <div class="flex items-start justify-between gap-3">
            <div>
              <div class="text-xs uppercase tracking-wide text-slate-500">Contributors</div>
              <div class="mt-1 font-semibold">Assign clear scopes. Keep load visible.</div>
            </div>
            <a href={~p"/app/contributors"} class="rounded-2xl border border-slate-200 bg-white px-3 py-2 text-sm hover:bg-slate-50">
              Invite
            </a>
          </div>

          <div class="mt-4 flex flex-wrap gap-2">
            <%= for {label, role} <- [{"All","all"},{"Frontend","frontend"},{"Ops","ops"},{"Design","design"},{"Legal","legal"}] do %>
              <button class={pill_button_class(@role_filter == role)}
                      phx-click="set_role_filter" phx-value-role={role}>
                <%= label %>
              </button>
            <% end %>
          </div>

          <div class="mt-4 grid grid-cols-1 sm:grid-cols-2 gap-4">
            <%= for c <- @contributors_filtered do %>
              <div class="rounded-2xl border border-slate-200 bg-white p-4">
                <div class="flex items-start justify-between gap-3">
                  <div class="flex items-center gap-3 min-w-0">
                    <div class="h-10 w-10 rounded-2xl border border-slate-200 bg-slate-50 flex items-center justify-center font-semibold">
                      <%= initials(c.name) %>
                    </div>
                    <div class="min-w-0">
                      <div class="font-semibold truncate"><%= c.name %></div>
                      <div class="text-sm text-slate-600 truncate"><%= c.role %></div>
                    </div>
                  </div>
                  <.pill intent={availability_intent(c.availability)}>
                    <%= availability_label(c.availability) %>
                  </.pill>
                </div>

                <div class="mt-3 flex flex-wrap gap-2">
                  <%= for s <- c.skills do %>
                    <.pill><%= s %></.pill>
                  <% end %>
                </div>

                <.subtle class="mt-3">
                  <%= c.scope_note %>
                </.subtle>

                <div class="mt-4 flex gap-2">
                  <button class="flex-1 rounded-2xl border border-slate-200 bg-white px-3 py-2 text-sm hover:bg-slate-50">
                    Define scope
                  </button>
                  <button class="flex-1 rounded-2xl bg-slate-900 text-white px-3 py-2 text-sm hover:bg-slate-800">
                    Send invite
                  </button>
                </div>
              </div>
            <% end %>
          </div>
        </.card>

        <!-- SOOH Check panel -->
        <.card>
          <div class="text-xs uppercase tracking-wide text-slate-500">SOOH check</div>
          <div class="mt-2 flex items-baseline justify-between">
            <div class="text-3xl font-semibold"><%= @check.score %></div>
            <div class="text-sm text-slate-600">/ 100 clarity</div>
          </div>
          <.subtle class="mt-2"><%= @check.summary %></.subtle>

          <div class="mt-4 space-y-2">
            <%= for issue <- Enum.take(@check.issues, 4) do %>
              <div class="rounded-2xl border border-slate-200 bg-slate-50 p-3">
                <div class="text-sm font-medium"><%= issue.title %></div>
                <div class="mt-1 text-sm text-slate-600"><%= issue.detail %></div>
              </div>
            <% end %>
          </div>

          <button class="mt-4 w-full rounded-2xl bg-slate-900 text-white px-3 py-2 text-sm hover:bg-slate-800"
                  phx-click="run_sooh_check">
            Fix issues
          </button>

          <div class="mt-6">
            <div class="text-xs uppercase tracking-wide text-slate-500">Recent activity</div>
            <div class="mt-3 space-y-2">
              <%= for item <- activity_seed() do %>
                <div class="rounded-2xl border border-slate-200 bg-white p-3">
                  <div class="text-xs text-slate-500"><%= item.ts %></div>
                  <div class="mt-1 text-sm font-medium"><%= item.title %></div>
                  <div class="mt-1 text-sm text-slate-600"><%= item.detail %></div>
                </div>
              <% end %>
            </div>
          </div>

          <div class="mt-6 rounded-2xl border border-slate-200 bg-slate-50 p-4">
            <div class="font-semibold">Next action</div>
            <.subtle class="mt-1">
              Link every open decision to a success criterion. This keeps work aligned when scope shifts.
            </.subtle>
          </div>
        </.card>
      </div>
    </.live_component>
    """
  end

  # --- helpers (kept in same file for simplicity) ---
  defp idea_form(project), do: to_form(%{}, as: "idea") |> assign_defaults(project)

  defp assign_defaults(form, _project), do: form

  defp next_milestone(milestones) do
    m =
      milestones
      |> Enum.filter(& &1.due_on)
      |> Enum.sort_by(& &1.due_on, Date)
      |> List.first()

    if m do
      %{title: m.title, due_label: due_label(m.due_on)}
    else
      %{title: "No due milestone", due_label: "—"}
    end
  end

  defp due_label(nil), do: "—"
  defp due_label(date), do: Calendar.strftime(date, "%b %d, %Y")

  defp relative_due(nil), do: "No due date"
  defp relative_due(date) do
    today = Date.utc_today()
    diff = Date.diff(date, today)
    cond do
      diff == 0 -> "Today"
      diff > 0 and diff <= 7 -> "+#{diff} days"
      diff > 7 -> "+#{div(diff, 7)} weeks"
      true -> "#{abs(diff)} days overdue"
    end
  end

  defp tab_class(true),
    do: "rounded-2xl bg-slate-900 text-white px-3 py-2 text-sm"
  defp tab_class(false),
    do: "rounded-2xl border border-slate-200 bg-white px-3 py-2 text-sm hover:bg-slate-50"

  defp pill_button_class(true),
    do: "rounded-full border border-slate-900 bg-slate-900 text-white px-3 py-1.5 text-xs font-medium"
  defp pill_button_class(false),
    do: "rounded-full border border-slate-200 bg-white text-slate-700 px-3 py-1.5 text-xs font-medium hover:bg-slate-50"

  defp initials(name) do
    name
    |> String.split(" ", trim: true)
    |> Enum.map(&String.first/1)
    |> Enum.take(2)
    |> Enum.join()
    |> String.upcase()
  end

  defp availability_label("available"), do: "Available"
  defp availability_label("pending"), do: "Pending"
  defp availability_label(_), do: "Part-time"

  defp availability_intent("available"), do: "success"
  defp availability_intent("pending"), do: "warn"
  defp availability_intent(_), do: "neutral"

  defp activity_seed do
    [
      %{ts: "Today 09:20", title: "Milestone updated", detail: "MVP Ready: due date set and owner confirmed."},
      %{ts: "Yesterday 16:05", title: "Decision added", detail: "Payment rails: compare Stripe vs local rails for cost/coverage."},
      %{ts: "2 days ago 11:40", title: "Task refined", detail: "Define acceptance criteria for search relevance and latency."}
    ]
  end

  defp count_projects(phase) do
    SoohWorkspace.Workspace.list_projects(phase: phase) |> length()
  end

  defp seed_fallback_project do
    # Not expected in seeded env. Keep safe.
    hd(SoohWorkspace.Workspace.list_projects()) || %{id: nil}
  end
end


