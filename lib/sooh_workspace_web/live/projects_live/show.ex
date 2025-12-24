
defmodule SoohWorkspaceWeb.ProjectsLive.Show do
  use SoohWorkspaceWeb, :live_view

  import SoohWorkspaceWeb.UIComponents
  alias SoohWorkspaceWeb.AppShell
  alias SoohWorkspace.Workspace
  alias SoohWorkspace.Workspace.{Project, Milestone, Task, Decision}

  @impl true
  def mount(%{"id" => id} = params, _session, socket) do
    project = Workspace.get_project_with_details!(id)
    check = Workspace.run_sooh_check(project.id)

    socket =
      socket
      |> assign(:page_title, "Project • #{project.name}")
      |> assign(:active, "projects")
      |> assign(:current_project, project)
      |> assign(:check, check)
      |> assign(:phase_tab, Map.get(params, "phase", project.phase))
      |> assign(:project_edit_open, false)
      |> assign(:milestone_open, false)
      |> assign(:task_open, false)
      |> assign(:decision_open, false)
      |> assign(:assign_owner_open, false)
      |> assign(:link_decision_open, false)
      |> assign(:project_form, to_form(Workspace.change_project(project), as: "project"))
      |> assign(:milestone_form, to_form(Workspace.change_milestone(%Milestone{}), as: "milestone"))
      |> assign(:task_form, to_form(Workspace.change_task(%Task{}), as: "task"))
      |> assign(:decision_form, to_form(Workspace.change_decision(%Decision{}), as: "decision"))
      |> assign(:fix_target, nil)

    {:ok, apply_fix_params(socket, params)}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    socket =
      socket
      |> assign(:phase_tab, Map.get(params, "phase", socket.assigns.phase_tab))

    {:noreply, apply_fix_params(socket, params)}
  end

  # Global top bar search routes to Tasks page (best ROI for “global search”)
  @impl true
  def handle_event("global_search", %{"q" => q}, socket) do
    {:noreply, push_navigate(socket, to: ~p"/app/tasks?q=#{q}&project_id=#{socket.assigns.current_project.id}")}
  end

  @impl true
  def handle_event("run_sooh_check", _params, socket) do
    p = reload(socket)
    {:noreply, assign(p, :check, Workspace.run_sooh_check(p.assigns.current_project.id))}
  end

  # Tabs
  def handle_event("set_phase_tab", %{"phase" => phase}, socket) do
    {:noreply, push_patch(socket, to: ~p"/app/projects/#{socket.assigns.current_project.id}?phase=#{phase}")}
  end

  # --- Project edit (Idea Canvas) ---
  def handle_event("open_project_edit", _p, socket),
    do: {:noreply, assign(socket, :project_edit_open, true)}

  def handle_event("close_project_edit", _p, socket),
    do: {:noreply, assign(socket, :project_edit_open, false)}

  def handle_event("validate_project", %{"project" => params}, socket) do
    cs =
      socket.assigns.current_project
      |> Workspace.change_project(params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :project_form, to_form(cs, as: "project"))}
  end

  def handle_event("save_project", %{"project" => params}, socket) do
    p = socket.assigns.current_project

    success_criteria =
      (params["success_criteria"] || "")
      |> String.split("\n")
      |> Enum.map(&String.trim/1)
      |> Enum.reject(&(&1 == ""))

    params = Map.put(params, "success_criteria", success_criteria)

    case Workspace.update_project(p, params) do
      {:ok, _} ->
        socket = reload(socket)
        {:noreply,
         socket
         |> assign(:project_edit_open, false)
         |> assign(:project_form, to_form(Workspace.change_project(socket.assigns.current_project), as: "project"))
         |> assign(:check, Workspace.run_sooh_check(socket.assigns.current_project.id))}

      {:error, cs} ->
        {:noreply, assign(socket, :project_form, to_form(cs, as: "project"))}
    end
  end

  # --- Milestones ---
  def handle_event("open_milestone", _p, socket), do: {:noreply, assign(socket, :milestone_open, true)}
  def handle_event("close_milestone", _p, socket), do: {:noreply, assign(socket, :milestone_open, false)}

  def handle_event("validate_milestone", %{"milestone" => params}, socket) do
    params = Map.put(params, "project_id", socket.assigns.current_project.id)

    cs =
      Workspace.change_milestone(%Milestone{}, params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :milestone_form, to_form(cs, as: "milestone"))}
  end

  def handle_event("create_milestone", %{"milestone" => params}, socket) do
    params = Map.put(params, "project_id", socket.assigns.current_project.id)

    case Workspace.create_milestone(params) do
      {:ok, _} ->
        socket = reload(socket)
        {:noreply,
         socket
         |> assign(:milestone_open, false)
         |> assign(:milestone_form, to_form(Workspace.change_milestone(%Milestone{}), as: "milestone"))
         |> assign(:check, Workspace.run_sooh_check(socket.assigns.current_project.id))}

      {:error, cs} ->
        {:noreply, assign(socket, :milestone_form, to_form(cs, as: "milestone"))}
    end
  end

  # --- Tasks (create under a milestone) ---
  def handle_event("open_task", %{"milestone_id" => mid}, socket) do
    {:noreply, assign(socket, task_open: true, fix_target: %{milestone_id: mid})}
  end

  def handle_event("close_task", _p, socket),
    do: {:noreply, assign(socket, task_open: false, fix_target: nil)}

  def handle_event("validate_task", %{"task" => params}, socket) do
    params =
      params
      |> Map.put_new("milestone_id", socket.assigns.fix_target && socket.assigns.fix_target.milestone_id)

    cs =
      Workspace.change_task(%Task{}, params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :task_form, to_form(cs, as: "task"))}
  end

  def handle_event("create_task", %{"task" => params}, socket) do
    params =
      params
      |> Map.put_new("milestone_id", socket.assigns.fix_target && socket.assigns.fix_target.milestone_id)
      |> normalize_tags()

    case Workspace.create_task(params) do
      {:ok, _} ->
        socket = reload(socket)
        {:noreply,
         socket
         |> assign(:task_open, false)
         |> assign(:task_form, to_form(Workspace.change_task(%Task{}), as: "task"))
         |> assign(:fix_target, nil)
         |> assign(:check, Workspace.run_sooh_check(socket.assigns.current_project.id))}

      {:error, cs} ->
        {:noreply, assign(socket, :task_form, to_form(cs, as: "task"))}
    end
  end

  def handle_event("toggle_task", %{"id" => id}, socket) do
    t = Workspace.get_task!(id)
    {:ok, _} = Workspace.update_task(t, %{is_done: not t.is_done})
    socket = reload(socket)
    {:noreply, assign(socket, :check, Workspace.run_sooh_check(socket.assigns.current_project.id))}
  end

  # --- Decisions ---
  def handle_event("open_decision", _p, socket), do: {:noreply, assign(socket, :decision_open, true)}
  def handle_event("close_decision", _p, socket), do: {:noreply, assign(socket, :decision_open, false)}

  def handle_event("validate_decision", %{"decision" => params}, socket) do
    params = Map.put(params, "project_id", socket.assigns.current_project.id)
    params = normalize_linked_criteria(params)

    cs =
      Workspace.change_decision(%Decision{}, params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :decision_form, to_form(cs, as: "decision"))}
  end

  def handle_event("create_decision", %{"decision" => params}, socket) do
    params =
      params
      |> Map.put("project_id", socket.assigns.current_project.id)
      |> normalize_linked_criteria()

    case Workspace.create_decision(params) do
      {:ok, _} ->
        socket = reload(socket)
        {:noreply,
         socket
         |> assign(:decision_open, false)
         |> assign(:decision_form, to_form(Workspace.change_decision(%Decision{}), as: "decision"))
         |> assign(:check, Workspace.run_sooh_check(socket.assigns.current_project.id))}

      {:error, cs} ->
        {:noreply, assign(socket, :decision_form, to_form(cs, as: "decision"))}
    end
  end

  # --- SOOH Fix: Assign milestone owner ---
  def handle_event("open_assign_owner", %{"milestone_id" => mid}, socket) do
    {:noreply, assign(socket, assign_owner_open: true, fix_target: %{milestone_id: mid})}
  end

  def handle_event("close_assign_owner", _p, socket),
    do: {:noreply, assign(socket, assign_owner_open: false, fix_target: nil)}

  def handle_event("assign_owner", %{"owner_contributor_id" => cid}, socket) do
    mid = socket.assigns.fix_target.milestone_id
    m = Workspace.get_milestone!(mid)
    {:ok, _} = Workspace.update_milestone(m, %{owner_contributor_id: cid})

    socket = reload(socket)

    {:noreply,
     socket
     |> assign(:assign_owner_open, false)
     |> assign(:fix_target, nil)
     |> assign(:check, Workspace.run_sooh_check(socket.assigns.current_project.id))}
  end

  # --- SOOH Fix: Link decision to success criteria ---
  def handle_event("open_link_decision", %{"decision_id" => did}, socket) do
    {:noreply, assign(socket, link_decision_open: true, fix_target: %{decision_id: did})}
  end

  def handle_event("close_link_decision", _p, socket),
    do: {:noreply, assign(socket, link_decision_open: false, fix_target: nil)}

  def handle_event("link_decision", %{"linked_success_criteria" => raw}, socket) do
    did = socket.assigns.fix_target.decision_id
    d = Workspace.get_decision!(did)

    linked =
      raw
      |> Enum.map(&String.trim/1)
      |> Enum.reject(&(&1 == ""))

    {:ok, _} = Workspace.update_decision(d, %{linked_success_criteria: linked})

    socket = reload(socket)

    {:noreply,
     socket
     |> assign(:link_decision_open, false)
     |> assign(:fix_target, nil)
     |> assign(:check, Workspace.run_sooh_check(socket.assigns.current_project.id))}
  end

  @impl true
  def render(assigns) do
    p = assigns.current_project

    milestones_for_tab =
      p.milestones
      |> Enum.filter(&(&1.phase == assigns.phase_tab))
      |> Enum.sort_by(&(&1.due_on || ~D[9999-12-31]))

    decisions_open = Enum.filter(p.decisions, &(&1.status == "open"))

    assigns =
      assigns
      |> assign(:milestones_for_tab, milestones_for_tab)
      |> assign(:decisions_open, decisions_open)

    ~H"""
    <.live_component module={AppShell}
      id="app-shell"
      current_user={@current_user}
      current_project={@current_project}
      active={@active}
      search=""
      search_event="global_search"
      search_submit="global_search">

      <div class="mb-6">
        <div class="text-xs uppercase tracking-wide text-slate-500">Project</div>
        <h1 class="mt-2 text-3xl font-semibold tracking-tight"><%= @current_project.name %></h1>
        <.subtle class="mt-2 max-w-3xl"><%= @current_project.purpose %></.subtle>

        <div class="mt-4 flex flex-wrap gap-2">
          <.pill><%= String.capitalize(@current_project.phase) %></.pill>
          <.pill intent="primary">SOOH</.pill>
          <.pill>Momentum: <%= @current_project.momentum_percent %>%</.pill>
        </div>

        <div class="mt-5 flex flex-col sm:flex-row gap-3">
          <button class="inline-flex justify-center rounded-2xl border border-slate-200 bg-white px-4 py-3 text-sm font-medium hover:bg-slate-50"
                  phx-click="open_project_edit">
            Edit idea canvas
          </button>
          <button class="inline-flex justify-center rounded-2xl bg-slate-900 text-white px-4 py-3 text-sm font-medium hover:bg-slate-800"
                  phx-click="open_milestone">
            Add milestone
          </button>
        </div>
      </div>

      <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <.card class="lg:col-span-2">
          <div class="flex items-start justify-between gap-3">
            <div>
              <div class="text-xs uppercase tracking-wide text-slate-500">Execution pathway</div>
              <div class="mt-1 font-semibold">Milestones and tasks by phase.</div>
            </div>
            <button class="rounded-2xl border border-slate-200 bg-white px-3 py-2 text-sm hover:bg-slate-50"
                    phx-click="open_decision">
              Add decision
            </button>
          </div>

          <div class="mt-4 flex gap-2">
            <button class={tab_class(@phase_tab == "creation")} phx-click="set_phase_tab" phx-value-phase="creation">Creation</button>
            <button class={tab_class(@phase_tab == "running")} phx-click="set_phase_tab" phx-value-phase="running">Running</button>
            <button class={tab_class(@phase_tab == "exit")} phx-click="set_phase_tab" phx-value-phase="exit">Exit</button>
          </div>

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
                      <button class="rounded-2xl border border-slate-200 bg-white px-3 py-1.5 text-xs hover:bg-slate-50"
                              phx-click="open_task" phx-value-milestone_id={m.id}>
                        Add task
                      </button>
                      <%= if is_nil(m.owner_contributor_id) do %>
                        <button class="rounded-2xl bg-slate-900 text-white px-3 py-1.5 text-xs hover:bg-slate-800"
                                phx-click="open_assign_owner" phx-value-milestone_id={m.id}>
                          Assign owner
                        </button>
                      <% end %>
                    </div>
                  </div>
                </div>

                <div class="mt-4 space-y-2">
                  <%= for t <- m.tasks do %>
                    <div class="rounded-2xl border border-slate-200 bg-slate-50 p-3">
                      <div class="flex items-start justify-between gap-3">
                        <div class="min-w-0">
                          <div class="font-medium"><%= t.title %></div>
                          <div class="mt-1 text-sm text-slate-600">
                            <span class="font-medium text-slate-700">Done means:</span>
                            <%= t.done_means || "Define acceptance to reduce rework." %>
                          </div>
                          <div class="mt-2 flex flex-wrap gap-2">
                            <%= for tag <- (t.tags || []) do %><.pill><%= tag %></.pill><% end %>
                          </div>
                        </div>
                        <button class={done_btn(t.is_done)} phx-click="toggle_task" phx-value-id={t.id}>
                          <%= if t.is_done, do: "Done", else: "Mark done" %>
                        </button>
                      </div>
                    </div>
                  <% end %>
                </div>
              </div>
            <% end %>
          </div>

          <div class="mt-6 rounded-2xl border border-slate-200 bg-slate-50 p-4">
            <div class="flex items-start justify-between gap-3">
              <div>
                <div class="font-semibold">Decision queue</div>
                <.subtle class="mt-1">Link decisions to success criteria to prevent drift.</.subtle>
              </div>
              <button class="rounded-2xl border border-slate-200 bg-white px-3 py-2 text-sm hover:bg-slate-50"
                      phx-click="open_decision">
                Add
              </button>
            </div>

            <div class="mt-4 space-y-2">
              <%= for d <- @decisions_open do %>
                <div class="rounded-2xl border border-slate-200 bg-white p-3">
                  <div class="flex items-start justify-between gap-3">
                    <div class="min-w-0">
                      <div class="font-medium truncate"><%= d.title %></div>
                      <div class="mt-1 text-sm text-slate-600"><%= d.impact_note %></div>
                      <div class="mt-2 flex flex-wrap gap-2">
                        <.pill intent={if (d.linked_success_criteria || []) == [], do: "warn", else: "success"}>
                          <%= if (d.linked_success_criteria || []) == [], do: "Not linked", else: "Linked" %>
                        </.pill>
                        <%= if (d.linked_success_criteria || []) == [] do %>
                          <button class="rounded-2xl bg-slate-900 text-white px-3 py-1.5 text-xs hover:bg-slate-800"
                                  phx-click="open_link_decision" phx-value-decision_id={d.id}>
                            Link to criteria
                          </button>
                        <% end %>
                      </div>
                    </div>
                    <.pill intent="warn">Open</.pill>
                  </div>
                </div>
              <% end %>
            </div>
          </div>
        </.card>

        <.card>
          <div class="text-xs uppercase tracking-wide text-slate-500">SOOH check</div>
          <div class="mt-2 flex items-baseline justify-between">
            <div class="text-3xl font-semibold"><%= @check.score %></div>
            <div class="text-sm text-slate-600">/ 100 clarity</div>
          </div>
          <.subtle class="mt-2"><%= @check.summary %></.subtle>

          <div class="mt-4 space-y-2">
            <%= for issue <- Enum.take(@check.issues, 6) do %>
              <div class="rounded-2xl border border-slate-200 bg-slate-50 p-3">
                <div class="text-sm font-medium"><%= issue.title %></div>
                <div class="mt-1 text-sm text-slate-600"><%= issue.detail %></div>
                <div class="mt-2">
                  <%= case issue.fix.action do %>
                    <% "assign_owner" -> %>
                      <button class="rounded-2xl bg-slate-900 text-white px-3 py-1.5 text-xs hover:bg-slate-800"
                              phx-click="open_assign_owner" phx-value-milestone_id={issue.fix.milestone_id}>
                        Fix: assign owner
                      </button>
                    <% "edit_task_done_means" -> %>
                      <a class="inline-flex rounded-2xl bg-slate-900 text-white px-3 py-1.5 text-xs hover:bg-slate-800"
                         href={~p"/app/tasks/#{issue.fix.task_id}?fix=done_means"}>
                        Fix: define done
                      </a>
                    <% "link_decision" -> %>
                      <button class="rounded-2xl bg-slate-900 text-white px-3 py-1.5 text-xs hover:bg-slate-800"
                              phx-click="open_link_decision" phx-value-decision_id={issue.fix.decision_id}>
                        Fix: link decision
                      </button>
                    <% _ -> %>
                      <span class="text-xs text-slate-600">Fix available in context.</span>
                  <% end %>
                </div>
              </div>
            <% end %>
          </div>

          <button class="mt-4 w-full rounded-2xl border border-slate-200 bg-white px-3 py-2 text-sm hover:bg-slate-50"
                  phx-click="run_sooh_check">
            Re-run SOOH Check
          </button>
        </.card>
      </div>

      <!-- Modals -->
      <%= if @project_edit_open do %>
        <.modal title="Edit idea canvas" close_event="close_project_edit">
          <.form for={@project_form} phx-change="validate_project" phx-submit="save_project" class="space-y-3">
            <div>
              <label class="text-xs uppercase tracking-wide text-slate-500">Purpose</label>
              <textarea name="project[purpose]" rows="2" class="mt-1 w-full rounded-2xl border border-slate-200 px-3 py-2 text-sm focus:ring-2 focus:ring-slate-400"><%= @current_project.purpose %></textarea>
            </div>

            <div>
              <label class="text-xs uppercase tracking-wide text-slate-500">Success criteria (one per line)</label>
              <textarea name="project[success_criteria]" rows="4" class="mt-1 w-full rounded-2xl border border-slate-200 px-3 py-2 text-sm focus:ring-2 focus:ring-slate-400"><%= Enum.join(@current_project.success_criteria || [], "\n") %></textarea>
            </div>

            <div class="grid grid-cols-1 sm:grid-cols-3 gap-3">
              <div>
                <label class="text-xs uppercase tracking-wide text-slate-500">Budget</label>
                <input name="project[constraints_budget]" value={@current_project.constraints_budget}
                       class="mt-1 w-full rounded-2xl border border-slate-200 px-3 py-2 text-sm focus:ring-2 focus:ring-slate-400"/>
              </div>
              <div>
                <label class="text-xs uppercase tracking-wide text-slate-500">Time</label>
                <input name="project[constraints_time]" value={@current_project.constraints_time}
                       class="mt-1 w-full rounded-2xl border border-slate-200 px-3 py-2 text-sm focus:ring-2 focus:ring-slate-400"/>
              </div>
              <div>
                <label class="text-xs uppercase tracking-wide text-slate-500">Scope</label>
                <input name="project[constraints_scope]" value={@current_project.constraints_scope}
                       class="mt-1 w-full rounded-2xl border border-slate-200 px-3 py-2 text-sm focus:ring-2 focus:ring-slate-400"/>
              </div>
            </div>

            <div>
              <label class="text-xs uppercase tracking-wide text-slate-500">Exit intent</label>
              <textarea name="project[exit_intent]" rows="2" class="mt-1 w-full rounded-2xl border border-slate-200 px-3 py-2 text-sm focus:ring-2 focus:ring-slate-400"><%= @current_project.exit_intent %></textarea>
            </div>

            <div>
              <label class="text-xs uppercase tracking-wide text-slate-500">One-line narrative</label>
              <input name="project[narrative]" value={@current_project.narrative}
                     class="mt-1 w-full rounded-2xl border border-slate-200 px-3 py-2 text-sm focus:ring-2 focus:ring-slate-400"/>
            </div>

            <div class="pt-2 flex gap-3">
              <button class="rounded-2xl bg-slate-900 text-white px-4 py-2 text-sm hover:bg-slate-800">Save</button>
              <button type="button" class="rounded-2xl border border-slate-200 bg-white px-4 py-2 text-sm hover:bg-slate-50"
                      phx-click="close_project_edit">Cancel</button>
            </div>
          </.form>
        </.modal>
      <% end %>

      <%= if @milestone_open do %>
        <.modal title="Add milestone" close_event="close_milestone">
          <.form for={@milestone_form} phx-change="validate_milestone" phx-submit="create_milestone" class="space-y-3">
            <input type="hidden" name="milestone[phase]" value={@phase_tab} />
            <div>
              <label class="text-xs uppercase tracking-wide text-slate-500">Title</label>
              <input name="milestone[title]" class="mt-1 w-full rounded-2xl border border-slate-200 px-3 py-2 text-sm focus:ring-2 focus:ring-slate-400"/>
            </div>
            <div>
              <label class="text-xs uppercase tracking-wide text-slate-500">Description</label>
              <textarea name="milestone[description]" rows="2" class="mt-1 w-full rounded-2xl border border-slate-200 px-3 py-2 text-sm focus:ring-2 focus:ring-slate-400"></textarea>
            </div>
            <div class="grid grid-cols-1 sm:grid-cols-2 gap-3">
              <div>
                <label class="text-xs uppercase tracking-wide text-slate-500">Owner</label>
                <select name="milestone[owner_contributor_id]" class="mt-1 w-full rounded-2xl border border-slate-200 px-3 py-2 text-sm focus:ring-2 focus:ring-slate-400">
                  <option value="">Unassigned</option>
                  <%= for c <- @current_project.contributors do %>
                    <option value={c.id}><%= c.name %> — <%= c.role %></option>
                  <% end %>
                </select>
              </div>
              <div>
                <label class="text-xs uppercase tracking-wide text-slate-500">Due on</label>
                <input type="date" name="milestone[due_on]" class="mt-1 w-full rounded-2xl border border-slate-200 px-3 py-2 text-sm focus:ring-2 focus:ring-slate-400"/>
              </div>
            </div>

            <div class="pt-2 flex gap-3">
              <button class="rounded-2xl bg-slate-900 text-white px-4 py-2 text-sm hover:bg-slate-800">Create</button>
              <button type="button" class="rounded-2xl border border-slate-200 bg-white px-4 py-2 text-sm hover:bg-slate-50"
                      phx-click="close_milestone">Cancel</button>
            </div>
          </.form>
        </.modal>
      <% end %>

      <%= if @task_open do %>
        <.modal title="Add task" close_event="close_task">
          <.form for={@task_form} phx-change="validate_task" phx-submit="create_task" class="space-y-3">
            <input type="hidden" name="task[milestone_id]" value={@fix_target.milestone_id} />
            <div>
              <label class="text-xs uppercase tracking-wide text-slate-500">Title</label>
              <input name="task[title]" class="mt-1 w-full rounded-2xl border border-slate-200 px-3 py-2 text-sm focus:ring-2 focus:ring-slate-400"/>
            </div>
            <div>
              <label class="text-xs uppercase tracking-wide text-slate-500">Done means</label>
              <textarea name="task[done_means]" rows="2" class="mt-1 w-full rounded-2xl border border-slate-200 px-3 py-2 text-sm focus:ring-2 focus:ring-slate-400"></textarea>
            </div>
            <div class="grid grid-cols-1 sm:grid-cols-2 gap-3">
              <div>
                <label class="text-xs uppercase tracking-wide text-slate-500">Tags (comma-separated)</label>
                <input name="task[tags]" class="mt-1 w-full rounded-2xl border border-slate-200 px-3 py-2 text-sm focus:ring-2 focus:ring-slate-400"
                       placeholder="Strategy, Clarity, Build"/>
              </div>
              <div>
                <label class="text-xs uppercase tracking-wide text-slate-500">Due on</label>
                <input type="date" name="task[due_on]" class="mt-1 w-full rounded-2xl border border-slate-200 px-3 py-2 text-sm focus:ring-2 focus:ring-slate-400"/>
              </div>
            </div>

            <div class="pt-2 flex gap-3">
              <button class="rounded-2xl bg-slate-900 text-white px-4 py-2 text-sm hover:bg-slate-800">Create</button>
              <button type="button" class="rounded-2xl border border-slate-200 bg-white px-4 py-2 text-sm hover:bg-slate-50"
                      phx-click="close_task">Cancel</button>
            </div>
          </.form>
        </.modal>
      <% end %>

      <%= if @decision_open do %>
        <.modal title="Add decision" close_event="close_decision">
          <.form for={@decision_form} phx-change="validate_decision" phx-submit="create_decision" class="space-y-3">
            <div>
              <label class="text-xs uppercase tracking-wide text-slate-500">Title</label>
              <input name="decision[title]" class="mt-1 w-full rounded-2xl border border-slate-200 px-3 py-2 text-sm focus:ring-2 focus:ring-slate-400"/>
            </div>
            <div>
              <label class="text-xs uppercase tracking-wide text-slate-500">Impact note</label>
              <textarea name="decision[impact_note]" rows="2" class="mt-1 w-full rounded-2xl border border-slate-200 px-3 py-2 text-sm focus:ring-2 focus:ring-slate-400"></textarea>
            </div>
            <div>
              <label class="text-xs uppercase tracking-wide text-slate-500">Link to success criteria</label>
              <div class="mt-2 space-y-2">
                <%= for item <- (@current_project.success_criteria || []) do %>
                  <label class="flex items-center gap-2 text-sm">
                    <input type="checkbox" name="decision[linked_success_criteria][]" value={item}
                           class="h-4 w-4 rounded border-slate-300"/>
                    <span><%= item %></span>
                  </label>
                <% end %>
              </div>
            </div>

            <div class="pt-2 flex gap-3">
              <button class="rounded-2xl bg-slate-900 text-white px-4 py-2 text-sm hover:bg-slate-800">Create</button>
              <button type="button" class="rounded-2xl border border-slate-200 bg-white px-4 py-2 text-sm hover:bg-slate-50"
                      phx-click="close_decision">Cancel</button>
            </div>
          </.form>
        </.modal>
      <% end %>

      <%= if @assign_owner_open do %>
        <.modal title="Assign milestone owner" close_event="close_assign_owner">
          <.subtle>Pick one accountable owner. SOOH prioritizes explicit ownership.</.subtle>
          <form class="mt-4 space-y-3" phx-submit="assign_owner">
            <select name="owner_contributor_id" class="w-full rounded-2xl border border-slate-200 px-3 py-2 text-sm focus:ring-2 focus:ring-slate-400">
              <%= for c <- @current_project.contributors do %>
                <option value={c.id}><%= c.name %> — <%= c.role %></option>
              <% end %>
            </select>
            <div class="pt-2 flex gap-3">
              <button class="rounded-2xl bg-slate-900 text-white px-4 py-2 text-sm hover:bg-slate-800">Assign</button>
              <button type="button" class="rounded-2xl border border-slate-200 bg-white px-4 py-2 text-sm hover:bg-slate-50"
                      phx-click="close_assign_owner">Cancel</button>
            </div>
          </form>
        </.modal>
      <% end %>

      <%= if @link_decision_open do %>
        <.modal title="Link decision to success criteria" close_event="close_link_decision">
          <.subtle>Select at least one criterion. This preserves alignment under change.</.subtle>
          <form class="mt-4 space-y-3" phx-submit="link_decision">
            <div class="space-y-2">
              <%= for item <- (@current_project.success_criteria || []) do %>
                <label class="flex items-center gap-2 text-sm">
                  <input type="checkbox" name="linked_success_criteria[]" value={item}
                         class="h-4 w-4 rounded border-slate-300"/>
                  <span><%= item %></span>
                </label>
              <% end %>
            </div>

            <div class="pt-2 flex gap-3">
              <button class="rounded-2xl bg-slate-900 text-white px-4 py-2 text-sm hover:bg-slate-800">Save</button>
              <button type="button" class="rounded-2xl border border-slate-200 bg-white px-4 py-2 text-sm hover:bg-slate-50"
                      phx-click="close_link_decision">Cancel</button>
            </div>
          </form>
        </.modal>
      <% end %>

    </.live_component>
    """
  end

  # --- helpers ---
  defp apply_fix_params(socket, %{"fix" => "assign_owner", "milestone_id" => mid}) do
    assign(socket, assign_owner_open: true, fix_target: %{milestone_id: mid})
  end

  defp apply_fix_params(socket, %{"fix" => "link_decision", "decision_id" => did}) do
    assign(socket, link_decision_open: true, fix_target: %{decision_id: did})
  end

  defp apply_fix_params(socket, _params), do: socket

  defp reload(socket) do
    p = Workspace.get_project_with_details!(socket.assigns.current_project.id)
    assign(socket, :current_project, p)
  end

  defp tab_class(true), do: "rounded-2xl bg-slate-900 text-white px-3 py-2 text-sm"
  defp tab_class(false), do: "rounded-2xl border border-slate-200 bg-white px-3 py-2 text-sm hover:bg-slate-50"

  defp done_btn(true),
    do: "rounded-2xl border border-slate-200 bg-white px-3 py-1.5 text-xs hover:bg-slate-50"
  defp done_btn(false),
    do: "rounded-2xl bg-slate-900 text-white px-3 py-1.5 text-xs hover:bg-slate-800"

  defp due_label(nil), do: "—"
  defp due_label(date), do: Calendar.strftime(date, "%b %d, %Y")

  defp normalize_tags(params) do
    case params["tags"] do
      nil -> params
      tags when is_list(tags) -> params
      tags when is_binary(tags) ->
        parsed =
          tags
          |> String.split(",")
          |> Enum.map(&String.trim/1)
          |> Enum.reject(&(&1 == ""))

        Map.put(params, "tags", parsed)
    end
  end

  defp normalize_linked_criteria(params) do
    case params["linked_success_criteria"] do
      nil -> params
      x when is_list(x) -> params
      x when is_binary(x) -> Map.put(params, "linked_success_criteria", [x])
    end
  end
attr :title, :string, required: true
  attr :close_event, :string, required: true
  slot :inner_block, required: true

  # Minimal modal component reused across LiveViews in this answer
  defp modal(assigns) do
    ~H"""
    <div class="fixed inset-0 z-50 flex items-center justify-center p-4" role="dialog" aria-modal="true">
      <div class="absolute inset-0 bg-slate-900/20" phx-click={@close_event} aria-hidden="true"></div>
      <div class="relative w-full max-w-2xl bg-white border border-slate-200 rounded-2xl p-5">
        <div class="flex items-start justify-between gap-3">
          <div>
            <div class="text-xs uppercase tracking-wide text-slate-500">Modal</div>
            <div class="mt-1 font-semibold"><%= @title %></div>
          </div>
          <button class="rounded-xl border border-slate-200 px-3 py-2 text-sm" phx-click={@close_event}>Close</button>
        </div>
        <div class="mt-4">
          <%= render_slot(@inner_block) %>
        </div>
      </div>
    </div>
    """
  end

end


