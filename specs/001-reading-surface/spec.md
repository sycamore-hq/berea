---
horizon: now
priority: high
---

# The Reading surface

A local dashboard and chat over this repo's Spec Kit writings. Two ways to
look at the same work; a third thing agents can trust (reviewed memory).

## Why

Morning should answer "what should we work on?" from a generated summary,
not from slurp-the-tree. Mid-day a design conversation becomes `spec.md`.
Afternoon implements a named task and checks the box in `tasks.md`. End of
day commits. Tomorrow starts from disk.

## Scope

- Traditional HTML dashboard: overview, roadmap, backlog, one-spec detail,
  constitution, graph, memory
- Deterministic chat envelope with visuals
- Derived SQLite overlay (pins, FTS, chat). Never a shadow board
- Zero-touch `bun run bootstrap && bun run dev`

## Out of scope

Markplane or Pinto as schema. Reimplementing `specify`. Auth. Editing
memory in the browser.

## User stories

1. A human opens `/` and sees in-flight specs, open tasks, blocked items,
   now-horizon, last context build, and pins in about twenty seconds.
2. An agent asks "what should we work on?" and gets a `summary` visual.
3. An agent marks `001-reading-surface#T012` done; `tasks.md` changes; context
   rebuilds.
