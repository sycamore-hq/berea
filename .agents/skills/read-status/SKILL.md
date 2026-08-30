---
name: read-status
description: Answer morning and status questions from generated context, not by slurping specs. Use when the human asks what to work on, what is blocked, the roadmap, a named NNN-slug, a T0xx task, or wants a chat visual from the dash.
---

# Read status

Morning reads a summary. It does not walk the tree.

## First

Rebuild if `.dash/context/summary.md` is missing or `/health` says
context is stale. See `rebuild-context`. Then examine.

## Routes

| Ask | Read | Visual |
|---|---|---|
| what should we work on / status | `.dash/context/summary.md` | summary |
| roadmap / now / next / later | summary + spec frontmatter horizons | roadmap |
| backlog / open tasks | summary + `.dash/context/active.md` | backlog |
| blocked | `.dash/context/blocked.md` | blocked |
| named `NNN-slug` | that feature's spec + plan + task counts | spec |
| named `T0xx` or `slug#T0xx` | that task slice and its spec | task |
| why did we / decision / regression | reviewed `memory/` + constitution | memory |

If the dash is up:

- `GET /api/summary`, `/api/backlog`, `/api/item/:ref`
- `POST /api/chat` when a visual is wanted

If the dash is down, read the generated markdown. Same answers. Degraded
is allowed. Inventing a board is not.

## Output

Cite the ref. One next action, taken from the files. Do not propose a
task that does not exist. Do not flip a checkbox from this skill.

## Stop

No `specs/` and no summary → say the house is empty, point at
`boot-dash`.
Named slug missing → say so. Do not guess a neighbor.

## Gotchas

- Reading every `spec.md` to answer "what next."
- Treating horizon as a new entity type. It is frontmatter or an
  inference from in-progress vs specified.
- Checking off work because the summary said it was done. Believe
  `tasks.md`.
