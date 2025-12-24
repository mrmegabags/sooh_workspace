defmodule SoohWorkspaceWeb.ContributorsLive.Index do
  use SoohWorkspaceWeb, :live_view

  import SoohWorkspaceWeb.UIComponents
  alias SoohWorkspaceWeb.AppShell
  alias SoohWorkspaceWeb.LiveHelpers
  alias SoohWorkspace.Workspace
  alias SoohWorkspace.Workspace.Contributor

  @impl true
  def mount(params, _session, socket) do
    current =
      params
      |> LiveHelpers.resolve_current_project()
      |> LiveHelpers.ensure_project!()

    project = Workspace.get_project_with_details!(current.id)

    socket =
      socket
      |> assign(:page_title, "Contributors • SOOH")
      |> assign(:active, "contributors")
      |> assign(:current_project, project)
      |> assign(:role_filter, Map.get(params, "role", "all"))
      |> assign(:invite_open, false)
      |> assign(
        :contrib_form,
        to_form(Workspace.change_contributor(%Contributor{}), as: "contributor")
      )
      |> assign(:contributors, filtered(project.contributors, socket.assigns.role_filter))

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    role = Map.get(params, "role", socket.assigns.role_filter)
    project = socket.assigns.current_project

    {:noreply,
     assign(socket, role_filter: role, contributors: filtered(project.contributors, role))}
  end

  @impl true
  def handle_event("global_search", %{"q" => q}, socket) do
    # Global search routes to tasks for utility; contributors can be filtered by role here
    {:noreply,
     push_navigate(socket,
       to: ~p"/app/tasks?q=#{q}&project_id=#{socket.assigns.current_project.id}"
     )}
  end

  def handle_event("set_role", %{"role" => role}, socket) do
    {:noreply,
     push_patch(socket,
       to: ~p"/app/contributors?role=#{role}&project_id=#{socket.assigns.current_project.id}"
     )}
  end

  def handle_event("open_invite", _p, socket), do: {:noreply, assign(socket, :invite_open, true)}

  def handle_event("close_invite", _p, socket),
    do: {:noreply, assign(socket, :invite_open, false)}

  def handle_event("validate_contributor", %{"contributor" => params}, socket) do
    params = Map.put(params, "project_id", socket.assigns.current_project.id)

    cs =
      Workspace.change_contributor(%Contributor{}, normalize_skills(params))
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :contrib_form, to_form(cs, as: "contributor"))}
  end

  def handle_event("create_contributor", %{"contributor" => params}, socket) do
    params =
      params
      |> Map.put("project_id", socket.assigns.current_project.id)
      |> normalize_skills()

    case Workspace.create_contributor(params) do
      {:ok, _} ->
        project = Workspace.get_project_with_details!(socket.assigns.current_project.id)

        {:noreply,
         socket
         |> assign(:current_project, project)
         |> assign(:contributors, filtered(project.contributors, socket.assigns.role_filter))
         |> assign(:invite_open, false)
         |> assign(
           :contrib_form,
           to_form(Workspace.change_contributor(%Contributor{}), as: "contributor")
         )
         |> put_flash(:info, "Contributor added.")}

      {:error, cs} ->
        {:noreply, assign(socket, :contrib_form, to_form(cs, as: "contributor"))}
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
      search=""
      search_event="global_search"
      search_submit="global_search"
    >
      <div class="mb-6">
        <div class="text-xs uppercase tracking-wide text-slate-500">Contributors</div>
        <h1 class="mt-2 text-3xl font-semibold tracking-tight">Clear roles. Explicit scope.</h1>
        <.subtle class="mt-2 max-w-3xl">
          Keep ownership visible. Reduce coordination drag. Use short scope notes.
        </.subtle>

        <div class="mt-5 flex flex-col sm:flex-row gap-3">
          <button
            class="inline-flex justify-center rounded-2xl bg-slate-900 text-white px-4 py-3 text-sm font-medium hover:bg-slate-800"
            phx-click="open_invite"
          >
            Invite contributor
          </button>
          <a
            href={~p"/app/projects/#{@current_project.id}"}
            class="inline-flex justify-center rounded-2xl border border-slate-200 bg-white px-4 py-3 text-sm font-medium hover:bg-slate-50"
          >
            Project detail
          </a>
        </div>
      </div>

      <div class="flex flex-wrap gap-2 mb-4">
        <%= for {label, role} <- [{"All","all"},{"Frontend","frontend"},{"Ops","ops"},{"Design","design"},{"Legal","legal"}] do %>
          <button class={pill_btn(@role_filter == role)} phx-click="set_role" phx-value-role={role}>
            {label}
          </button>
        <% end %>
      </div>

      <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
        <%= for c <- @contributors do %>
          <.card>
            <div class="flex items-start justify-between gap-3">
              <div class="flex items-center gap-3 min-w-0">
                <div class="h-10 w-10 rounded-2xl border border-slate-200 bg-slate-50 flex items-center justify-center font-semibold">
                  {initials(c.name)}
                </div>
                <div class="min-w-0">
                  <div class="font-semibold truncate">{c.name}</div>
                  <div class="text-sm text-slate-600 truncate">{c.role}</div>
                </div>
              </div>
              <.pill intent={availability_intent(c.availability)}>
                {availability_label(c.availability)}
              </.pill>
            </div>

            <div class="mt-3 flex flex-wrap gap-2">
              <%= for s <- (c.skills || []) do %>
                <.pill>{s}</.pill>
              <% end %>
            </div>

            <.subtle class="mt-3">{c.scope_note}</.subtle>

            <div class="mt-4 flex gap-2">
              <button class="flex-1 rounded-2xl border border-slate-200 bg-white px-3 py-2 text-sm hover:bg-slate-50">
                Define scope
              </button>
              <button class="flex-1 rounded-2xl bg-slate-900 text-white px-3 py-2 text-sm hover:bg-slate-800">
                Send invite
              </button>
            </div>
          </.card>
        <% end %>
      </div>

      <%= if @invite_open do %>
        <.modal title="Invite / add contributor" close_event="close_invite">
          <.form
            for={@contrib_form}
            phx-change="validate_contributor"
            phx-submit="create_contributor"
            class="space-y-3"
          >
            <div>
              <label class="text-xs uppercase tracking-wide text-slate-500">Name</label>
              <input
                name="contributor[name]"
                class="mt-1 w-full rounded-2xl border border-slate-200 px-3 py-2 text-sm focus:ring-2 focus:ring-slate-400"
              />
            </div>

            <div class="grid grid-cols-1 sm:grid-cols-2 gap-3">
              <div>
                <label class="text-xs uppercase tracking-wide text-slate-500">Role</label>
                <select
                  name="contributor[role]"
                  class="mt-1 w-full rounded-2xl border border-slate-200 px-3 py-2 text-sm focus:ring-2 focus:ring-slate-400"
                >
                  <option value="Frontend">Frontend</option>
                  <option value="Ops">Ops</option>
                  <option value="Design">Design</option>
                  <option value="Legal">Legal</option>
                </select>
              </div>
              <div>
                <label class="text-xs uppercase tracking-wide text-slate-500">Availability</label>
                <select
                  name="contributor[availability]"
                  class="mt-1 w-full rounded-2xl border border-slate-200 px-3 py-2 text-sm focus:ring-2 focus:ring-slate-400"
                >
                  <option value="available">Available</option>
                  <option value="part_time">Part-time</option>
                  <option value="pending">Pending</option>
                </select>
              </div>
            </div>

            <div>
              <label class="text-xs uppercase tracking-wide text-slate-500">
                Skills (comma-separated)
              </label>
              <input
                name="contributor[skills]"
                class="mt-1 w-full rounded-2xl border border-slate-200 px-3 py-2 text-sm focus:ring-2 focus:ring-slate-400"
                placeholder="LiveView UI, Ops, Legal terms"
              />
            </div>

            <div>
              <label class="text-xs uppercase tracking-wide text-slate-500">Scope note</label>
              <textarea
                name="contributor[scope_note]"
                rows="2"
                class="mt-1 w-full rounded-2xl border border-slate-200 px-3 py-2 text-sm focus:ring-2 focus:ring-slate-400"
                placeholder="Own X. Deliver Y. Define done as Z."
              ></textarea>
            </div>

            <div class="pt-2 flex gap-3">
              <button class="rounded-2xl bg-slate-900 text-white px-4 py-2 text-sm hover:bg-slate-800">
                Add
              </button>
              <button
                type="button"
                class="rounded-2xl border border-slate-200 bg-white px-4 py-2 text-sm hover:bg-slate-50"
                phx-click="close_invite"
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

  defp filtered(contributors, "all"), do: contributors

  defp filtered(contributors, role) do
    r = String.downcase(role)
    Enum.filter(contributors, &(String.downcase(&1.role) == r))
  end

  defp normalize_skills(params) do
    case params["skills"] do
      nil ->
        params

      s when is_list(s) ->
        params

      s when is_binary(s) ->
        parsed =
          s
          |> String.split(",")
          |> Enum.map(&String.trim/1)
          |> Enum.reject(&(&1 == ""))

        Map.put(params, "skills", parsed)
    end
  end

  defp pill_btn(true),
    do:
      "rounded-full border border-slate-900 bg-slate-900 text-white px-3 py-1.5 text-xs font-medium"

  defp pill_btn(false),
    do:
      "rounded-full border border-slate-200 bg-white text-slate-700 px-3 py-1.5 text-xs font-medium hover:bg-slate-50"

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

  # Modal component same as above
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
