# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     SoohWorkspace.Repo.insert!(%SoohWorkspace.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.
alias SoohWorkspace.{Repo, Accounts}
alias SoohWorkspace.Workspace
alias SoohWorkspace.Workspace.{Project, Contributor, Milestone, Task, Decision}

# Demo user
{:ok, _} =
  case Accounts.get_user_by_email("demo@sooh.local") do
    nil ->
      Accounts.register_user(%{email: "demo@sooh.local", password: "demo-password-1234"})

    user ->
      {:ok, user}
  end

# Project: Greenfield Marketplace
{:ok, project} =
  Workspace.create_project(%{
    name: "Greenfield Marketplace",
    phase: "creation",
    momentum_percent: 46,
    purpose: "Launch a low-latency marketplace MVP for verified suppliers and repeat buyers.",
    success_criteria: [
      "First 50 verified suppliers onboarded",
      "100 buyer sign-ups with 20 repeat purchases",
      "Median search response < 300ms",
      "Unit economics validated on pilot cohort"
    ],
    constraints_budget: "Lean (runway-first)",
    constraints_time: "8 weeks to MVP readiness",
    constraints_scope: "MVP: listings, search, basic payments, support loop",
    exit_intent:
      "Reach product-market signal and prepare for scale or strategic acquisition pathway.",
    narrative: "Build a clear MVP pathway with defined acceptance and explicit ownership."
  })

# Contributors (4 cards)
{:ok, c1} =
  Workspace.create_contributor(%{
    project_id: project.id,
    name: "Amina N.",
    role: "Frontend",
    availability: "available",
    skills: ["LiveView UI", "Tailwind", "Performance"],
    scope_note: "Own UI clarity, responsive layout, and low-latency interactions."
  })

{:ok, c2} =
  Workspace.create_contributor(%{
    project_id: project.id,
    name: "David K.",
    role: "Ops",
    availability: "part_time",
    skills: ["Process", "Vendors", "Onboarding"],
    scope_note: "Own supplier onboarding workflow and operational readiness checks."
  })

{:ok, c3} =
  Workspace.create_contributor(%{
    project_id: project.id,
    name: "Leah M.",
    role: "Design",
    availability: "available",
    skills: ["Product UX", "Systems", "Copy"],
    scope_note: "Own interaction definitions, microcopy, and UI consistency."
  })

{:ok, c4} =
  Workspace.create_contributor(%{
    project_id: project.id,
    name: "Kiptoo J.",
    role: "Legal",
    availability: "pending",
    skills: ["Terms", "Compliance", "Risk"],
    scope_note: "Own marketplace terms, payment compliance, and vendor agreements."
  })

# Milestone: MVP Ready (Creation)
{:ok, mvp} =
  Workspace.create_milestone(%{
    project_id: project.id,
    phase: "creation",
    title: "MVP Ready",
    description: "Functional marketplace with defined acceptance and measurable latency.",
    owner_contributor_id: c1.id,
    due_on: Date.add(Date.utc_today(), 10)
  })

# Tasks (some missing done_means to trigger SOOH issues)
{:ok, _} =
  Workspace.create_task(%{
    milestone_id: mvp.id,
    title: "Search + results relevance baseline",
    done_means: "Top 10 results match query intent in 8/10 test cases; median response < 300ms.",
    tags: ["Clarity", "Build", "Quality"],
    due_on: Date.add(Date.utc_today(), 3),
    is_done: false
  })

{:ok, _} =
  Workspace.create_task(%{
    milestone_id: mvp.id,
    title: "Supplier onboarding v1",
    done_means: "",
    tags: ["People", "Ops"],
    due_on: Date.add(Date.utc_today(), 7),
    is_done: false
  })

{:ok, _} =
  Workspace.create_task(%{
    milestone_id: mvp.id,
    title: "Payments integration decision",
    done_means: "",
    tags: ["Strategy", "Clarity"],
    due_on: Date.add(Date.utc_today(), 0),
    is_done: false
  })

# Decisions (one missing linked_success_criteria to trigger issue)
{:ok, _} =
  Workspace.create_decision(%{
    project_id: project.id,
    title: "Choose payment rails",
    impact_note: "Affects cost, coverage, compliance, and conversion rate.",
    status: "open",
    linked_success_criteria: []
  })

{:ok, _} =
  Workspace.create_decision(%{
    project_id: project.id,
    title: "Define supplier verification threshold",
    impact_note: "Controls trust, fraud risk, and onboarding speed.",
    status: "open",
    linked_success_criteria: ["First 50 verified suppliers onboarded"]
  })
