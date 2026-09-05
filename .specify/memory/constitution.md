# Berea Constitution

This is the gate. Later writings (spec, plan, tasks) must not contradict it.
Replace sections via `/speckit.constitution` when the house actually changes
its mind — do not shadow these principles in `memory/`.

## I. The writings are the work

Constitution, `specs/<NNN>-<slug>/spec.md`, `plan.md`, and `tasks.md` are the
source of intent and backlog. There is no second board. SQLite is an overlay:
pins, chat, FTS, snapshots. It is never a copy of the writings.

## II. If it isn’t in the files, it isn’t so

Agents read the files. Generated context (`.dash/context/`) is derived and
rebuildable. Do not hand-edit it. Do not treat a chat answer as canon.

## III. Task status is the checkbox

A task is done when its checkbox in that feature’s `tasks.md` is marked.
Cite work as `003-auth#T012`. Do not explode tasks into one file per task.
Do not invent TASK-xxxxx or EPIC-xxxxx files.

## IV. Feature status is derived

- No `plan.md` → specified
- `plan.md`, tasks incomplete → planned or in-progress
- All tasks checked → done
- Constitution check failing → blocked (show the gate)

Do not store feature status in SQLite.

## V. Memory is reviewed

Facts that are not spec-kit artifacts live in `memory/` with frontmatter.
The action agent may append `memory/sessions/` only. Decisions, regressions,
and conventions enter through a curator patch and a human merge. Memory
commits start with `memory:`.

Personal identity and preferences stay in a separate vault. Not this repo.

## VI. Skills are procedures; AGENTS.md is an index

Skills live at `.agents/skills/<name>/SKILL.md`. `AGENTS.md` and `CLAUDE.md`
point; they do not become encyclopedias.

## VII. Local, zero-touch, no vendor schema

The reading surface boots with `bun run bootstrap && bun run dev`. No
interactive prompts. No accounts. Operate on the files even if `specify`
is missing. Markplane and Pinto are sources of ideas, not formats.

## VIII. Horizon is optional frontmatter

A spec may set `horizon: now | next | later` on `spec.md` only. If absent,
infer: in-progress → now; specified-but-unplanned → next. A derived Done
outranks explicit frontmatter: a finished spec is later. Horizon is not
an Epic type.
