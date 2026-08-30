---
name: implement-task
description: Implement one named spec-kit task, then flip only that checkbox in tasks.md and rebuild context. Use in the afternoon, when the human names a T0xx or slug#T0xx, or says implement that task. Do not use for status, spec writing, or memory curation.
---

# Implement task

One named task. One checkbox. No extras.

## First

Examine. The human must name the work as `NNN-slug#T0xx` or a `T0xx`
that resolves to one spec. Refuse unnamed work.

Read, in order:

1. That feature's `spec.md`
2. `plan.md` if present
3. The task line and any unchecked prerequisites in `tasks.md`

If a prerequisite is open, stop. Cite it. Do not "also do T011."

## Isolation

Worktree or a clean branch for this task. Do not share a dirty tree
with another in-flight task.

## Do the work

Implement only what the task names. Match the plan's stack when a plan
exists. Match existing code shape. Do not refactor neighbors.

Run the deterministic checks the repo already has. Prefer those over
an LLM verdict.

## Close the task

1. Flip only that task's checkbox in `tasks.md`. Preserve the rest of
   the document. Do not explode tasks into one file each.
2. Rebuild context (`rebuild-context`). Never hand-edit `.dash/context/`.
3. Allowed extra writes this turn: `memory/sessions/` append.
4. Open a PR if the human wants one. Cite the ref in the message.

Do not edit constitution, reviewed memory, `AGENTS.md` (beyond a link),
or generated context.

## Stop

- Prerequisites open.
- Three attempts, same failure, no new file evidence → session note,
  stop. Retry is not a new round.
- Delete, publish, production, rewrite of house files → human.
- The task cannot be finished without changing the spec → stop and
  say the spec must move first.

## Gotchas

- Flipping two checkboxes because they were "small."
- Checking the box before the check ran.
- Treating "the tests I just wrote" as proof when they assert nothing
  the spec asked for.
- Starting implement on a spec that has no `tasks.md`.
