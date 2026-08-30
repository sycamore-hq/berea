---
name: curate-memory
description: Classify a transcript or diff into a memory proposal or a spec amendment. Never check off a task. Use after a session, when the human says remember this, capture the regression, or this belongs in the writings. Use as Curator, not during an implement-task turn.
---

# Curate memory

Reviewed memory is canon. Sessions are proposals. The human merges.

## Must not

- Flip a checkbox
- Edit `memory/decisions|regressions|conventions`
- Edit constitution or `spec.md` in this skill (propose a patch)
- Silently commit
- Copy constitution or spec bodies into memory. Point at them.

Action/chat on a work turn may only append `memory/sessions/`.

## Classify

Look at the transcript and the diff. Pick one:

| Kind | Where the proposal goes | When |
|---|---|---|
| spec amendment | patch against `specs/NNN-slug/spec.md` (or plan/tasks) | the fact is about what we are building |
| constitution | patch against `.specify/memory/constitution.md` | it is a house principle |
| convention | `memory/sessions/` proposal for `memory/conventions/` | how we work, not a feature |
| regression | `memory/sessions/` proposal for `memory/regressions/` | a failure that must not recur |
| discard | session note saying why | chatter, duplicates, already in a writing |

Frontmatter on any memory file:

```yaml
---
as_of: YYYY-MM-DD
supersedes:
source: session/... | pr/... | human | spec:NNN-slug
confidence: high | medium | low
status: proposal
---
```

Leave `status: proposal`. Human sets `active` on merge.
Commits that land memory start with `memory:`.

## Stop

The same fact already lives in a spec → point at it, discard the note.
Unsure which kind → propose and say so. Do not guess canon.

## Gotchas

- Checking T012 because the session "finished it." That is a different
  loop and a different role.
- Writing personal preferences into this repo. They stay in a vault.
- Treating FTS hits as reviewed memory. FTS is derived.
