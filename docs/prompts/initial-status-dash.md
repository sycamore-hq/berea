# Build: Project Status Dashboard (Spec Kit + chat + reviewed memory)

You are implementing a dual-surface project status system for one Git
repository.

The **on-disk standard** is GitHub Spec Kit
(https://github.com/github/spec-kit): constitution, specs, plans, tasks.
Do not invent a vendor board format. Do not adopt Markplane or Pinto as
the schema. Those tools are a source of *ideas* only (see Borrowed
ideas). If a file already exists in spec-kit shape, read it. Do not
transliterate it into TASK-xxxxx.md.

A human-directed agent will bootstrap, run, and later extend this with
no interactive prompts and no undocumented env vars.

Read this whole file before writing code. Prefer small, typed modules
over frameworks. Do not invent a second backlog. Do not invent a second
source of truth for facts.

## Mission

Give a human two ways to look at the same work:

1. A traditional web dashboard: constitution, spec list / roadmap,
   one-spec detail (spec + plan + tasks), backlog across specs, status.
2. An agent chat that answers in context and emits visuals the chat host
   renders.

Give agents a third thing they can trust:

3. A typed, reviewed memory tree. Procedures live in skills. Facts that
   are *not* spec-kit artifacts live in Markdown with frontmatter. Git
   is history. SQLite FTS is derived.

The day this system must make true (idea from Markplane's narrative,
wired to spec-kit artifacts):

**Morning** — "What should we work on?" Answer from a generated
context summary: in-progress tasks, blocked items, specs in flight,
next planned task.

**Mid-day** — A design conversation becomes a `specs/NNN-slug/spec.md`
(and later plan.md / tasks.md) in the repo, not a ticket in a SaaS app.

**Afternoon** — "Implement T012 in 003-auth." The agent reads spec +
plan + that task and its prerequisites, then marks the task done in
`tasks.md`. Context regenerates.

**End of day** — Commit. Tomorrow starts from files.

If a surface cannot support that day, it is not done.

## Non-negotiables

- Source of intent and work: Spec Kit layout in the product repo.
    `.specify/memory/constitution.md`
    `specs/<NNN>-<slug>/spec.md`
    `specs/<NNN>-<slug>/plan.md`
    `specs/<NNN>-<slug>/tasks.md`
    plus the other spec-kit siblings when present
    (`research.md`, `data-model.md`, `quickstart.md`, `contracts/`,
    `checklists/`).
- Never treat SQLite as a copy of those files. Never rewrite spec-kit
  files into another product's schema.
- Mutations of task checkboxes / status go through small, explicit
  edits to `tasks.md` (or a `specify` / speckit command if present).
  Prefer preserving the document. Do not explode tasks.md into one
  file per task unless spec-kit itself does that.
- Source of *agent* knowledge that is not a spec artifact: `memory/`
  (conventions, regressions, session proposals). Personal identity
  and preferences stay in a separate vault repo.
- Overlay / index: SQLite via `bun:sqlite` at `.dash/dash.sqlite`.
  Gitignore the db; commit schema and migrations. Rebuildable.
- `AGENTS.md` and `CLAUDE.md` are an index, not an encyclopedia.
  Point at the constitution, `specs/`, generated context, skills,
  `memory/README.md`, dash endpoints, boot commands. Cap ~80 lines.
- Skills live at `.agents/skills/<name>/SKILL.md`.
- Memory writes go through a review gate. The action/chat agent may
  only append `memory/sessions/` in the work turn.
- Stack:
  - Domain + view-model: Melange, OCaml syntax (not Reason).
  - HTTP: Hono on Bun.
  - Frontend: Melange-compiled JS. HTML templates + small client JS.
    No React unless a binding forces it.
- Zero-touch boot: `bun run bootstrap && bun run dev`
- No interactive prompts.
- If spec-kit CLI (`specify`) is missing, still operate on the files.
  Do not require Markplane, Pinto, or `specify` to render the dash.
- If Melange/opam is missing, run from committed `_generated/` JS.
- Local only. No accounts, no cloud PM tool.

## Spec Kit contract (the standard)

After `specify init` (or an equivalent manual scaffold):

```text
.specify/
  memory/constitution.md     # principles; gates later commands
  templates/                 # spec-kit owned
  scripts/
specs/
  001-short-slug/
    spec.md                  # what / why
    plan.md                  # how (stack, constitution check)
    tasks.md                 # actionable checklist, dependency order
    research.md              # optional, from plan phase
    data-model.md            # optional
    quickstart.md            # optional
    contracts/               # optional
    checklists/              # optional
  002-another/
    ...
```

Workflow the dash must understand, not implement:

1. constitution
2. specify → spec.md
3. clarify → updates spec.md
4. plan → plan.md
5. checklist
6. tasks → tasks.md
7. analyze (read-only consistency)
8. implement
9. converge (spec vs code; may append tasks)

Status of a **feature** is derived:

- no plan.md → specified
- plan.md, tasks incomplete → planned / in-progress
- all tasks checked and converge clean → done
- constitution check failing → blocked (show the gate)

Status of a **task** is the checkbox (and any trailing status tag
already in the file). Do not invent a parallel status column in
SQLite.

Roadmap horizons (idea from Markplane; not a spec-kit type):

A spec may opt into a horizon via YAML frontmatter *on spec.md only*:

```yaml
---
horizon: now | next | later
priority: critical | high | medium | low
---
```

If frontmatter is absent, horizon is inferred: in-progress specs are
`now`, specified-but-unplanned are `next`, constitution-only ideas
stay out of the roadmap until a spec exists. Do not require a new
entity type called Epic.

IDs:

- Feature: directory name `NNN-slug` (stable).
- Task: the identifier already in tasks.md (`T001`, `- [ ] T012`, etc.).
  Cite as `003-auth#T012`.

Wiki-style `[[003-auth]]` or `[[003-auth#T012]]` in rendered markdown
is a borrowed idea. Resolve against `specs/`.

## Borrowed ideas (not borrowed formats)

From **Markplane** (https://github.com/zerowand01/markplane):

- Generated, token-capped context files so an agent does not slurp
  every spec.
- INDEX.md as a router: list ids/titles/status, then load one file.
- Now / next / later as a horizon, orthogonal to priority.
- Morning question answered from a summary, not from the raw tree.
- `blocks` / `depends_on` when tasks.md already expresses order;
  surface that as a graph. Do not create a side-car relations DB.
- Files are the database. Git is the changelog.

From **Pinto** (https://github.com/moriturus/pinto):

- Small Scrum vocabulary when it fits a spec's tasks (rank, points)
  as optional frontmatter or task-line tags. Never required.
- File backend, human-diffable.

From **markplane-memory**:

- Personal vault ≠ project specs.
- Daily logs (what happened) ≠ specs (what needs to happen).

From **Spec Kit** (the actual standard):

- Constitution gates the rest.
- spec.md is what/why; plan.md is how; tasks.md is the backlog
  *for that feature*.
- Converge against artifacts, do not drift a shadow board.

## Generated context (ours, rebuildable)

Because we are not Markplane, we generate our own derived layer:

```text
.dash/context/
  summary.md          # ~1000 tokens. Target for "what should we work on?"
  active.md           # specs + tasks in flight
  blocked.md          # constitution failures, unmet task deps
  metrics.md          # counts by feature status and horizon
INDEX.md              # at specs/INDEX.md — router across features
```

`bun run index` (and POST /api/sync) rebuilds these from the spec
tree + constitution. They are derived. Gitignore `.dash/context/`
or mark them generated. Never hand-edit.

Reading order for agents:

1. `.dash/context/summary.md`
2. `specs/INDEX.md` or the feature's folder listing
3. that feature's spec.md / plan.md / the relevant task slice
4. constitution only when gating or "why we don't do X"

Cap BoardContext ~4k tokens.

## Memory tree

```text
memory/
  README.md
  decisions/       # only if it is not already constitution or a spec
  regressions/
  conventions/
  sessions/        # proposals
```

Frontmatter:

```yaml
---
as_of: 2026-08-28
supersedes: memory/conventions/2026-05-testing.md
source: session/abc | pr/142 | human | spec:003-auth
confidence: high | medium | low
status: active | superseded | rejected | proposal
---
```

Do not copy constitution principles or spec.md bodies into memory/.
Point at them.

## Skills

```text
.agents/skills/
  read-status/SKILL.md
  curate-memory/SKILL.md
  boot-dash/SKILL.md
```

`read-status` — morning → summary.md / `/api/summary`. Named
`NNN-slug` or `T0xx` → that spec slice. Picture → POST `/api/chat`.

`curate-memory` — transcript + diff. Classify: spec amendment
candidate / convention / regression / discard. Never check off a
task from this skill.

`boot-dash` — bootstrap, ports, degraded modes.

## Review gate

Action agent must not, in the work turn:

- edit `memory/decisions|regressions|conventions`
- rewrite `AGENTS.md` / `CLAUDE.md` beyond a link
- silently commit those trees
- hand-edit generated `.dash/context/`

Allowed: session proposal, checkbox edits in tasks.md, rebuild index,
open a PR.

Curator emits a patch. Human merges or `review --diff`.
Memory commits start with `memory:`.

## Overlay schema (SQLite)

Derived only.

```sql
pins(
  ref TEXT PK,                 -- 003-auth or 003-auth#T012
  reason TEXT NOT NULL,
  pinned_at TEXT NOT NULL
)

views(
  id TEXT PK,
  name TEXT NOT NULL,
  kind TEXT NOT NULL,
  query_json TEXT NOT NULL,
  created_at TEXT NOT NULL
)

chat_threads(
  id TEXT PK,
  title TEXT NOT NULL,
  created_at TEXT NOT NULL
)

chat_messages(
  id TEXT PK,
  thread_id TEXT NOT NULL,
  role TEXT NOT NULL,
  content_json TEXT NOT NULL,
  created_at TEXT NOT NULL
)

snapshots(
  id TEXT PK,
  taken_at TEXT NOT NULL,
  summary_md TEXT NOT NULL
)

CREATE VIRTUAL TABLE memory_fts USING fts5(
  path, title, body, kind, as_of, tokenize = 'porter'
);
```

`bun run index` walks `memory/**/*.md` (skip sessions by default)
and spec titles. No embedding store in v1. No shadow task table.

## Surfaces

### A. Traditional dashboard

```text
GET  /                     overview from generated summary + metrics
GET  /roadmap              specs grouped by horizon
GET  /backlog              open tasks across specs, dependency order
GET  /specs                index of all features
GET  /specs/:slug          spec.md + plan.md + tasks.md in one page
GET  /constitution         constitution.md (read-only)
GET  /graph                task/spec edges from tasks.md order + links
GET  /memory               reviewed agent notes (read-only)
GET  /health               { specs, overlay, context_age_s }

GET  /api/summary
GET  /api/roadmap
GET  /api/backlog
GET  /api/specs
GET  /api/specs/:slug
GET  /api/item/:ref        slugs or slug#task
GET  /api/search?q=
GET  /api/memory?q=
POST /api/sync             rebuild context + FTS
POST /api/index
POST /api/task             { ref, done: true } → edit tasks.md checkbox
POST /api/pins
```

Overview readable in 20 seconds: specs in flight, open tasks,
blocked, now-horizon, last context build, pins.

HTML works with JS off for spec and constitution pages.

No edit UI for memory/ or constitution. Task done-ness is a
checkbox write to tasks.md, then sync.

### B. Agent chat

```json
POST /api/chat
{
  "thread_id": "optional",
  "message": "what should we work on?",
  "context": {
    "route": "optional dash path",
    "focus_ids": ["003-auth#T012"],
    "horizon": "now"
  }
}
```

ChatEnvelope:

```json
{
  "text": "markdown",
  "visuals": [
    {
      "kind": "summary | roadmap | backlog | spec | task | graph | blocked | memory | note_md",
      "title": "string",
      "data": {}
    }
  ],
  "citations": ["003-auth", "003-auth#T012", "memory/conventions/testing.md"]
}
```

```text
summary:  { in_flight, blocked, priority_queue, metrics }
roadmap:  { horizons: [{ name, specs: [SpecCard] }] }
backlog:  { items: [TaskCard] }
spec:     { card, spec_md, plan_present, task_counts }
task:     { card, body, spec_slug, blockers }
graph:    { nodes, edges }
blocked:  { items: [{ card, why }] }
memory:   { hits: [{ path, title, as_of, status, excerpt }] }

SpecCard: { slug, title, horizon?, priority?, status, open_tasks, total_tasks }
TaskCard: { ref, title, done, spec_slug, priority? }
```

Deterministic router when no LLM key:

- "what should we" / "status" → kind=summary
- "roadmap" / "horizon" / "now" → kind=roadmap
- "backlog" / "tasks" → kind=backlog
- "blocked" → kind=blocked
- "constitution" → kind=note_md with constitution excerpt
- slug or T0xx → kind=spec or kind=task
- "why did we" / "decision" / "regression" → kind=memory
  (and search constitution)

Named surfaces always get a visual.

## Two agents

- **Action / chat** — reads generated context + FTS + skills.
  May write sessions/. May toggle tasks.md checkboxes.
- **Curator** — never toggles tasks. Proposes memory patches or
  "this belongs in spec.md" patches.

## Shape

```text
tools/status-dash/
  package.json
  bun.lock
  dune-project
  src/
    domain.ml
    speckit.ml          # parse constitution, spec.md, plan.md, tasks.md
    overlay.ml
    memory.ml
    context_gen.ml      # summary / INDEX builders
    views.ml
    envelope.ml
  js/
    server.ts
    chat_router.ts
    index_memory.ts
  overlay/migrations/
  _generated/
  scripts/bootstrap.ts
  fixtures/
    constitution.md
    specs/001-example/spec.md
    specs/001-example/tasks.md
```

Repo root:

```text
AGENTS.md
CLAUDE.md
.specify/memory/constitution.md
specs/
.agents/skills/
memory/
tools/status-dash/
```

## Bootstrap

1. bun install
2. mkdir -p .dash
3. apply migrations
4. PROJECT_ROOT from `SPEC_ROOT`, else `../..`, else cwd
5. if `specs/` missing, create it empty; if constitution missing,
   write a one-page stub that says "replace via /speckit.constitution"
6. bun run index  (generate context + FTS)
7. write .dash/BOOTSTRAP.md
8. exit 0 unless sqlite migration failed

`bun run dev` → Hono on `0.0.0.0:$PORT` (8787).

`bun run check` parses fixtures, roundtrips ChatEnvelope and
tasks.md checkboxes.

## Quality bar

- Types model spec-kit documents, not a fantasy ticket schema.
- Optional frontmatter is `option` in OCaml.
- No ORM. Parameterized SQL.
- Visible errors: no specs, stale context, parse failure.
- Dash README ~20 lines.

## Out of scope

Markplane or Pinto as runtime or schema. Reimplementing `specify`.
Auth, SaaS, editing memory in the browser, embedding stores as
source of truth, personal prefs in AGENTS.md, Reason syntax,
Next.js, Docker-as-the-only-path.

## Done when

```text
cd tools/status-dash
bun run bootstrap && bun run dev
```

- GET /health is ok (or explicit empty-specs)
- GET / shows numbers that match generated summary.md
- GET /specs lists directories under specs/
- GET /specs/001-example renders spec + tasks fixture
- POST /api/chat `{"message":"what should we work on?"}` → kind=summary
- POST /api/chat `{"message":"what's blocked"}` → kind=blocked
- toggling a fixture checkbox via POST /api/task + sync updates backlog
- constitution is citable and not copied into memory/
- AGENTS.md is still an index
- no human typed during bootstrap

## Coverage checklist

Standard (spec-kit)

- [ ] constitution.md
- [ ] specs/NNN-slug/{spec,plan,tasks}.md
- [ ] feature status derived, not stored in sqlite
- [ ] task status = checkbox in tasks.md
- [ ] no TASK-xxxxx / EPIC-xxxxx files

Borrowed ideas

- [ ] generated token-capped summary
- [ ] specs/INDEX.md router
- [ ] now/next/later horizon (frontmatter or inferred)
- [ ] morning / mid-day / afternoon / EOD story works
- [ ] graph from stated task order
- [ ] personal vault kept out

Surfaces

- [ ] dashboard, roadmap, backlog, spec detail, constitution, graph
- [ ] chat visuals: summary, roadmap, backlog, spec, task, blocked, memory

Memory

- [ ] review-gated memory/
- [ ] curator ≠ action agent
- [ ] SQLite derived only
`}

