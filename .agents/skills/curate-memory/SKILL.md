---
name: curate-memory
description: Classify a transcript or diff into a memory proposal or a spec amendment. Never check off a task. Use after a session, when the human says remember this, capture the regression, or this belongs in the writings. Use as Curator, not during an implement-task turn.
---

# Curate memory

Reviewed memory is canon. Sessions are proposals. The human merges.

Input: transcript + diff. Output: a proposed patch.

## Classify each fact

| Kind | Destination | When |
|---|---|---|
| Already in constitution or a spec | discard | point at the writing |
| Changes what/why of a feature | patch `specs/<slug>/spec.md` | it is about what we are building |
| House principle | patch `.specify/memory/constitution.md` | it gates future work |
| How we write files or code | `memory/conventions/` | how we work, not a feature |
| A failure we must not repeat | `memory/regressions/` | it recurred or cost a session |
| A choice no writing records | `memory/decisions/` | neither constitution nor spec holds it |
| Noise | discard | chatter, duplicates |

Anything bound for `memory/` lands first as a proposal under
`memory/sessions/`. The human promotes it.

## Frontmatter

```yaml
---
as_of: YYYY-MM-DD
supersedes:
source: session/<id> | pr/<n> | human | spec:<slug>
confidence: high | medium | low
status: proposal
---
```

Leave `status: proposal`. The human sets `active` on merge.

## Must not

- Flip a checkbox or edit `tasks.md`
- Edit `memory/decisions|regressions|conventions` directly
- Edit the constitution or a `spec.md` from this skill — propose a patch
- Copy constitution principles or spec bodies into `memory/`. Point at them.
- Commit. The human commits, with a message starting `memory:`

On a work turn, action/chat may only append `memory/sessions/`.

## Stop

The same fact already lives in a writing → point at it, discard the note.
Unsure which kind → propose and say so. Do not guess canon.

## Gotchas

- Checking T012 because the session "finished it." Different loop,
  different role.
- Writing personal preferences into this repo. They stay in a vault.
- Treating FTS hits as reviewed memory. FTS is derived.
