# Berea loops

Skills teach how. Loops decide when.
If it isn’t in the files, it isn’t so.

This is not CrossR. Do not speak Forge, AVRIL, or AXEL here.

## L0 Examine — always

Cite or withdraw. Generated context is a view. Conversation is not
evidence. Skill: `examine`.

## L1 The Day — outer

```
Morning    read-status from .dash/context/summary.md
Mid-day    specify-writing → specs/NNN-slug/spec.md
Afternoon  implement-task → one checkbox → rebuild-context
End of day commit. Tomorrow starts from disk.
```

Owner: the human. Heartbeat: morning, and any "what should we work on?"

## L2 Specify — mid-day

Conversation becomes `spec.md`. What and why only. Cap clarify at five
questions encoded back into the file. Skill: `specify-writing`.

## L3 Plan and tasks

`plan.md` then dependency-ordered `tasks.md`. Constitution check lives
in the plan. Analyze must be clean enough to pick a named task. Use
the `specify` CLI if present; files still win if it is not.

## L4 Implement — afternoon

Named `NNN-slug#T0xx` only. Worktree. Prerequisites must be checked.
Flip that one box. Rebuild. Three failures with no new evidence: stop.
Skill: `implement-task`.

## L5 Converge — feature close

Spec vs plan vs tasks vs tree. Append missing tasks. Never delete
tasks. Never edit code inside this loop. Skill: `converge-writings`.

## L6 Curate — not the work turn

Classify. Propose under `memory/sessions/` or as a spec patch. Human
merges. Commit starts with `memory:`. Never flip a checkbox.
Skill: `curate-memory`. Role: Curator.

## L7 Index — derived

`bun run index` / `POST /api/sync`. Do not hand-edit `.dash/context/`.
Skill: `rebuild-context`.

## Roles

Action may read writings, append sessions, flip checkboxes, rebuild
index, open a PR.

Action may not edit reviewed memory, rewrite house files beyond a
link, hand-edit generated context, or silently commit memory.

Curator proposes. Human merges.

## Stop rules (every loop)

- Cannot cite it → do not claim it
- Prerequisites open → do not start
- Same failure three times → stop
- Irreversible effect → human
- Derived drift → rebuild, do not edit
