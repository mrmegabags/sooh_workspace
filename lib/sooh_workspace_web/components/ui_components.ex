defmodule SoohWorkspaceWeb.UIComponents do
  use Phoenix.Component

  attr :class, :string, default: ""
  slot :inner_block, required: true

  def card(assigns) do
    ~H"""
    <section class={[
      "bg-white border border-slate-200 rounded-2xl p-4 sm:p-5",
      "shadow-sm shadow-slate-100/60",
      @class
    ]}>
      {render_slot(@inner_block)}
    </section>
    """
  end

  # neutral|primary|success|warn
  attr :intent, :string, default: "neutral"
  attr :class, :string, default: ""
  slot :inner_block, required: true

  def pill(assigns) do
    base = "inline-flex items-center rounded-full border px-2.5 py-1 text-xs font-medium"

    theme =
      case assigns.intent do
        "primary" -> "border-slate-900 text-slate-900 bg-slate-50"
        "success" -> "border-emerald-200 text-emerald-700 bg-emerald-50"
        "warn" -> "border-amber-200 text-amber-700 bg-amber-50"
        _ -> "border-slate-200 text-slate-700 bg-white"
      end

    assigns = assign(assigns, :classes, [base, theme, assigns.class])

    ~H"""
    <span class={@classes}>{render_slot(@inner_block)}</span>
    """
  end

  attr :value, :integer, required: true

  def progress(assigns) do
    v = min(max(assigns.value, 0), 100)
    assigns = assign(assigns, :v, v)

    ~H"""
    <div
      class="w-full h-2 rounded-full bg-slate-100 border border-slate-200"
      role="progressbar"
      aria-valuemin="0"
      aria-valuemax="100"
      aria-valuenow={@v}
    >
      <div class="h-2 rounded-full bg-slate-900" style={"width: #{@v}%"}></div>
    </div>
    """
  end

  attr :label, :string, required: true
  attr :class, :string, default: ""
  slot :inner_block, required: true

  def kpi(assigns) do
    ~H"""
    <div class={["flex flex-col gap-1", @class]}>
      <div class="text-xs uppercase tracking-wide text-slate-500">{@label}</div>
      <div class="text-2xl font-semibold text-slate-900">{render_slot(@inner_block)}</div>
    </div>
    """
  end

  attr :class, :string, default: ""
  slot :inner_block, required: true

  def subtle(assigns) do
    ~H"""
    <p class={["text-sm text-slate-600 leading-6", @class]}>{render_slot(@inner_block)}</p>
    """
  end
end
