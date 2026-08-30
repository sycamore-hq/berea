---
name: specify-writing
description: Turn a design conversation into specs/NNN-slug/spec.md (what and why only). Use at mid-day, when the human is shaping a feature, when they say specify or write the spec, or when talk has not yet landed in a file.
---

# Specify writing

A conversation that does not land in a file did not happen.

## First

Examine. Read the constitution. Read `specs/INDEX.md`.

This loop does not write `plan.md` or `tasks.md`. Those are later
writings.

## Allocate the slug

If the feature already has a directory, amend that `spec.md`.
If not, take the next `NNN` from existing directories and a short slug
from the human's words. Do not reuse a number.

```text
specs/NNN-slug/spec.md
```

Optional frontmatter on `spec.md` only:

```yaml
---
horizon: now | next | later
priority: critical | high | medium | low
---
```

Do not invent Epic or TASK-xxxxx files.

## What belongs in spec.md

- What and why
- User-visible behavior
- Acceptance that can be checked later
- Open questions, listed
- Non-goals

What does not:

- Tech stack, libraries, folder layout (that is `plan.md`)
- A task checklist (that is `tasks.md`)
- Copies of constitution text (point at it)

Prefer the spec-kit template if `.specify/templates/` is present.
If the `specify` CLI is present you may use it. The file is the
interface either way.

## Clarify

If the spec is underspecified, ask at most five questions that change
the writing. Encode answers back into `spec.md`. Do not keep a side
list in chat.

## After

Rebuild the index. Do not hand-edit `.dash/context/`.
Do not flip tasks. There are none yet.

## Stop

Constitution would reject the feature → write that gate down and stop.
Human has not read the spec → do not pretend it is blessed.
The human is talking implementation → switch to plan, do not smuggle
how into what.

## Gotchas

- Putting the stack in spec.md because the human mentioned Bun.
- Opening a ticket in some other tool.
- Writing three specs from one conversation without being asked.
