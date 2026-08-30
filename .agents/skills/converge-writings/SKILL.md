---
name: converge-writings
description: Check the tree against spec.md, plan.md, and tasks.md. Report gaps with citations. Append missing tasks only. Use when closing a feature, after a stretch of implement-task, or when the human says converge, did we miss anything, or is this feature done.
---

# Converge writings

This is spec-kit converge. Append-only. Never edit code to hide a gap.
Never delete a task to make the feature look done.

## First

Examine the feature named by the human. If none, use the in-flight spec
from `.dash/context/active.md`. If several are in flight, ask which.

Read `spec.md`, `plan.md` if present, `tasks.md`, and the parts of the
tree the plan said would exist.

If the `specify` CLI is present you may run `/speckit.converge` or the
equivalent. Still write the result in the files.

## Verdicts

**Converged.** Every acceptance in the spec has a cited place in the
tree or in a checked task. Open questions in the spec are either
answered in the writing or explicitly deferred. Say so with citations.

**Gaps.** List each gap as a citation: which sentence in spec or plan
has no task and no code. Append new tasks under a `Convergence`
heading in that feature's `tasks.md`. Do not reorder or rewrite
existing tasks except to add that heading and the new lines.

Then stop. Implement is a different loop.

## Feature status (derived)

- no plan.md → specified
- plan.md, tasks open → planned / in progress
- all tasks checked and converge clean → done
- constitution check failing → blocked

Do not store that status in SQLite as source.

## Stop

Cannot name the feature → do not converge the whole repo.
Tempted to "just fix it" in code → that is `implement-task`.
Tempted to mark a vague task done so the list is green → leave it.

## Gotchas

- Declaring done because the agent is tired.
- Editing spec.md during converge to match whatever shipped.
- Copying converge notes into `memory/` instead of into `tasks.md`.
