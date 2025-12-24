defmodule SoohWorkspaceWeb.AppShell do
  use SoohWorkspaceWeb, :html
  import SoohWorkspaceWeb.UIComponents

  attr :search_event, :string, default: nil
  attr :search_submit, :string, default: nil
  attr :current_user, :any, required: true
  attr :current_project, :any, required: true
  attr :active, :string, required: true
  attr :search, :string, default: ""
  slot :inner_block, required: true

  def render(assigns) do
    ~H"""
    <div class="min-h-screen">
      <!-- Sticky top bar -->
      <header class="sticky top-0 z-30 bg-white/95 backdrop-blur border-b border-slate-200">
        <div class="mx-auto max-w-7xl px-4 sm:px-6 h-14 flex items-center gap-3">
          <button
            type="button"
            class="sm:hidden inline-flex items-center justify-center rounded-xl border border-slate-200 px-3 py-2
                   focus:outline-none focus:ring-2 focus:ring-slate-400"
            phx-click={JS.toggle(to: "#mobile-drawer")}
            aria-label="Open navigation"
          >
            <span class="text-sm font-medium">Menu</span>
          </button>

          <div class="flex items-center gap-3 min-w-0">
            <div class="h-9 w-9 rounded-2xl border border-slate-200 bg-slate-50 flex items-center justify-center font-semibold">
              SOOH
            </div>
            <div class="min-w-0">
              <div class="text-sm font-semibold truncate">SOOH Workspace</div>
              <div class="text-xs text-slate-600 truncate">
                Simple • Orderly • Organized • Harmonized (SOOH)
              </div>
            </div>
          </div>

          <div class="flex-1"></div>
          <form
            class="hidden md:flex items-center gap-2"
            role="search"
            aria-label="Search"
            phx-change={@search_event}
            phx-submit={@search_submit}
          >
            <input
              name="q"
              value={@search}
              placeholder="Search projects, tasks, people…"
              class="w-80 rounded-2xl border border-slate-200 bg-white px-3 py-2 text-sm
                focus:outline-none focus:ring-2 focus:ring-slate-400"
              phx-debounce="300"
            />
            <button type="submit" class="hidden"></button>
            <button
              type="button"
              class="hidden lg:inline-flex rounded-2xl border border-slate-200 px-3 py-2 text-sm
          hover:bg-slate-50 focus:outline-none focus:ring-2 focus:ring-slate-400"
              aria-label="New"
            >
              New
            </button>
          </form>

          <a
            href={~p"/app/snapshots/new"}
            class="inline-flex items-center rounded-2xl bg-slate-900 text-white px-3 py-2 text-sm hover:bg-slate-800 focus:outline-none focus:ring-2 focus:ring-slate-400"
          >
            Publish Snapshot
          </a>

          <div
            class="h-9 w-9 rounded-2xl border border-slate-200 bg-white flex items-center justify-center text-sm font-semibold"
            aria-label="Profile"
          >
            {initials(@current_user.email)}
          </div>
        </div>
      </header>

      <div class="mx-auto max-w-7xl px-4 sm:px-6 py-6 grid grid-cols-1 sm:grid-cols-[260px_1fr] gap-6">
        <!-- Desktop sidebar -->
        <aside class="hidden sm:block sticky top-20 self-start">
          <nav class="flex flex-col gap-2">
            <.nav_item active={@active == "dashboard"} href={~p"/app"} label="Dashboard" />
            <.nav_item active={@active == "projects"} href={~p"/app/projects"} label="Projects" />
            <.nav_item active={@active == "tasks"} href={~p"/app/tasks"} label="Tasks" />
            <.nav_item
              active={@active == "contributors"}
              href={~p"/app/contributors"}
              label="Contributors"
            />
          </nav>

          <div class="mt-4">
            <.card>
              <div class="flex items-start justify-between gap-3">
                <div class="min-w-0">
                  <div class="text-xs uppercase tracking-wide text-slate-500">Current project</div>
                  <div class="font-semibold truncate">{@current_project.name}</div>
                  <div class="mt-1 flex items-center gap-2">
                    <.pill>{String.capitalize(@current_project.phase)}</.pill>
                    <.pill intent="primary">{@current_project.sooh_badge}</.pill>
                  </div>
                </div>
                <a
                  href={~p"/app/projects/#{@current_project.id}"}
                  class="text-sm underline text-slate-700 hover:text-slate-900"
                >
                  Open
                </a>
              </div>

              <div class="mt-4">
                <div class="flex items-center justify-between text-xs text-slate-600">
                  <span>Momentum</span>
                  <span>{@current_project.momentum_percent}%</span>
                </div>
                <div class="mt-2">
                  <.progress value={@current_project.momentum_percent} />
                </div>
              </div>
            </.card>
          </div>

          <div class="mt-4">
            <.card class="bg-slate-50">
              <div class="text-xs uppercase tracking-wide text-slate-500">SOOH rule</div>
              <div class="mt-1 font-semibold">If it is not clear in 30 seconds, it is not SOOH.</div>
              <.subtle class="mt-2">
                Run a fast validation to enforce ownership, definitions of done, and decision linkage.
              </.subtle>
              <button
                type="button"
                class="mt-4 w-full rounded-2xl border border-slate-200 bg-white px-3 py-2 text-sm
                      hover:bg-slate-50 focus:outline-none focus:ring-2 focus:ring-slate-400"
                phx-click="run_sooh_check"
              >
                Run SOOH Check
              </button>
            </.card>
          </div>
        </aside>
        
    <!-- Mobile drawer -->
        <div
          id="mobile-drawer"
          class="sm:hidden hidden fixed inset-0 z-40"
          aria-label="Mobile navigation"
        >
          <div
            class="absolute inset-0 bg-slate-900/20"
            phx-click={JS.hide(to: "#mobile-drawer")}
            aria-hidden="true"
          >
          </div>
          <div class="absolute left-0 top-0 bottom-0 w-80 bg-white border-r border-slate-200 p-4 overflow-y-auto">
            <div class="flex items-center justify-between">
              <div class="font-semibold">Navigation</div>
              <button
                class="rounded-xl border border-slate-200 px-3 py-2 text-sm"
                phx-click={JS.hide(to: "#mobile-drawer")}
                aria-label="Close"
              >
                Close
              </button>
            </div>

            <div class="mt-4 flex flex-col gap-2">
              <.nav_item active={@active == "dashboard"} href={~p"/app"} label="Dashboard" />
              <.nav_item active={@active == "projects"} href={~p"/app/projects"} label="Projects" />
              <.nav_item active={@active == "tasks"} href={~p"/app/tasks"} label="Tasks" />
              <.nav_item
                active={@active == "contributors"}
                href={~p"/app/contributors"}
                label="Contributors"
              />
              <.nav_item active={@active == "settings"} href={~p"/app/settings"} label="Settings" />
            </div>
          </div>
        </div>

        <main class="min-w-0">
          {render_slot(@inner_block)}
        </main>
      </div>
    </div>
    """
  end

  attr :active, :boolean, required: true
  attr :href, :string, required: true
  attr :label, :string, required: true

  def nav_item(assigns) do
    base =
      "w-full rounded-2xl px-3 py-2 text-sm border focus:outline-none focus:ring-2 focus:ring-slate-400"

    cls =
      if assigns.active do
        [base, "bg-slate-900 text-white border-slate-900"]
      else
        [base, "bg-white text-slate-800 border-slate-200 hover:bg-slate-50"]
      end

    assigns = assign(assigns, :cls, cls)

    ~H"""
    <a href={@href} class={@cls} aria-current={@active && "page"}>
      {@label}
    </a>
    """
  end

  defp initials(email) when is_binary(email) do
    email
    |> String.split("@")
    |> hd()
    |> String.slice(0, 2)
    |> String.upcase()
  end
end
