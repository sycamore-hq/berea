---
name: examine
description: Cite every claim against the writings on disk. Withdraw anything that cannot be pointed at. Use when answering what is true, what we decided, what a spec or task says, or before treating generated context or memory as fact. Use on every Berea turn; other skills assume this one has already run.
---

# Examine

You are in Berea. Read the files. Do not take the agent's word for it.

> They received the word with all readiness of mind, and searched the
> scriptures daily, whether those things were so. — Acts 17:11

## Writings

- Constitution: `.specify/memory/constitution.md`
- Specs: `specs/<NNN>-<slug>/{spec,plan,tasks}.md` and siblings
- Index: `specs/INDEX.md`
- Generated context (derived): `.dash/context/summary.md`
- Reviewed memory: `memory/` except `sessions/`
- Session proposals: `memory/sessions/` (not canon)
- This house: `README.md`, `AGENTS.md`, `LOOPS.md`

Generated context is a view. Quote it, then confirm against the writing
it summarizes when the answer will change work.

## Reading order

1. `.dash/context/summary.md` if the question is status or "what next"
2. `specs/INDEX.md` or the named `NNN-slug`
3. The feature file that holds the claim (`spec.md`, `plan.md`, the task slice)
4. Constitution only for gates and "why we don't"
5. Reviewed memory only for facts that are not already a spec artifact

Do not slurp the tree. Cap what you load. Cite `003-auth` or
`003-auth#T012`.

## Rules

- If it isn’t in the files, it isn’t so.
- Conversation memory is not evidence.
- Model confidence is not evidence.
- Do not invent a second backlog or a status column.
- Task status is the checkbox in `tasks.md`.
- Feature status is derived from which files exist and which boxes remain.
- Point at constitution or spec.md. Do not copy their bodies into memory.

## Stop

Cannot cite it → withdraw the claim.
Derived files look stale → rebuild context before answering status.
The writing and the summary disagree → believe the writing, then rebuild.

## Gotchas

- Answering from the last chat turn as if it were canon.
- Treating `memory/sessions/` as reviewed memory.
- Citing a slug that is not a directory under `specs/`.
- Restating constitution principles inside a spec or a memory note.
