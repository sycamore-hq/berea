---
name: rebuild-context
description: Rebuild derived context and the spec index from the writings. Use before answering morning/status if context is stale or missing, after flipping a task checkbox, after writing a spec, and when /health reports old context. Never hand-edit .dash/context/.
---

# Rebuild context

Derived files are a view. Rebuild them. Do not author them.

## Outputs

```text
.dash/context/summary.md     # ~1000 tokens. Morning target.
.dash/context/active.md
.dash/context/blocked.md
.dash/context/metrics.md
specs/INDEX.md               # router across features
.dash/dash.sqlite            # FTS overlay, gitignored
```

## How

From `tools/status-dash`:

```text
bun run index
```

or `POST /api/sync` if the dash is up. `/api/index` is the same handler.

If `_generated/` is missing, the dash is unbuilt. Say that. Point at
`boot-dash`. Do not invent a parallel generator.

## After

Confirm `summary.md` numbers match `specs/` directories and the
checkboxes you can see. If they disagree, the generator is wrong.
Do not "fix" the markdown by hand — fix the generator under
`tools/status-dash/src/`, and `bun run check` before believing it.

## Stop

Migration or sqlite failure → fail visible. Do not answer status
from a half-written summary.

## Gotchas

- Editing summary.md to add a task the writings do not have.
- Committing `.dash/dash.sqlite`.
- Skipping rebuild after a checkbox flip, then answering morning
  from yesterday.
