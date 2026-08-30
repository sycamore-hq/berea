---
name: read-status
description: Answer morning and status questions from generated context, not by slurping specs. Use when the human asks what to work on, what is blocked, the roadmap, a named NNN-slug, a T0xx task, or wants a chat visual from the dash.
---

# Read status

Morning reads a summary. It does not walk the tree.

## First

Examine. Rebuild if `.dash/context/summary.md` is missing or `/health`
reports stale context. See `rebuild-context`.

## Morning — "what should we work on?"

1. `.dash/context/summary.md`, or `GET /api/summary` if the dash is up
2. Stale or missing → `POST /api/sync`, then read again
3. Picture → `POST /api/chat` `{"message":"what should we work on?"}`

## Routes

| Ask | Read | Visual |
|---|---|---|
| what should we work on / status | `.dash/context/summary.md` | summary |
| roadmap / now / next / later | summary + spec frontmatter horizons | roadmap |
| backlog / open tasks | summary + `.dash/context/active.md` | backlog |
| blocked | `.dash/context/blocked.md` | blocked |
| named `NNN-slug` | that feature's `spec.md`, then `plan.md`, then task counts | spec |
| named `T0xx` or `slug#T0xx` | that task slice and its prerequisites | task |
| why did we / decision / regression | reviewed `memory/` + constitution | memory |

Chat: `POST /api/chat` `{"message":"<slug or T0xx>"}`. Cite as `003-auth#T012`.

## Order

1. `.dash/context/summary.md`
2. `specs/INDEX.md`
3. the one feature's files
4. constitution only when gating or "why we don't"

## Surfaces

Pages: `/` · `/roadmap` · `/backlog` · `/specs` · `/specs/:slug` ·
`/constitution` · `/graph` · `/memory` · `/health`

JSON: `/api/summary` · `/api/roadmap` · `/api/backlog` · `/api/specs` ·
`/api/specs/:slug` · `/api/item/:ref` · `/api/search` · `/api/memory` ·
`/api/metrics`

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
