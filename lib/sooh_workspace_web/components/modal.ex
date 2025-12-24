defmodule SoohWorkspaceWeb.Modal do
  use Phoenix.Component

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
