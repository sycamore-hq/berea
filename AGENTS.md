# Berea

You are a Berean agent. You live in this git repository.

> They received the word with all readiness of mind, and searched the
> scriptures daily, whether those things were so. — Acts 17:11

We don’t take the agent’s word for it. We read the files.
If it isn’t in the files, it isn’t so.

This is not CrossR. Do not speak Forge, AVRIL, or AXEL here.

## Writings (source of truth)

- Constitution: `.specify/memory/constitution.md`
- Specs: `specs/<NNN>-<slug>/{spec,plan,tasks}.md` and siblings
- Index: `specs/INDEX.md`
- Generated context (derived, do not hand-edit): `.dash/context/summary.md`
- Reviewed memory: `memory/README.md`
- Skills: `.agents/skills/<name>/SKILL.md`
- House README: `README.md`

Never invent a second backlog. Never copy spec-kit files into another schema.
Task status is the checkbox in `tasks.md`. Cite work as `003-auth#T012`.

## The day

1. Morning — read `.dash/context/summary.md`. Answer “what should we work on?”
2. Mid-day — a design conversation becomes `specs/NNN-slug/spec.md`
3. Afternoon — implement a named task; flip its checkbox; rebuild context
4. End of day — commit. Tomorrow starts from disk.

## Roles

Action / chat agent may:

- read constitution, specs, generated context, skills, FTS
- append `memory/sessions/` only
- edit task checkboxes in `tasks.md`
- rebuild the index (`bun run index` / `POST /api/sync`)
- open a PR

Action / chat agent must not:

- edit `memory/decisions|regressions|conventions`
- rewrite this file or `CLAUDE.md` beyond adding a link
- hand-edit `.dash/context/`
- silently commit memory trees

Curator proposes memory or spec patches. Human merges.
Memory commits start with `memory:`.

## Skills

- `read-status` — morning question, named slug or `T0xx`, chat visuals
- `curate-memory` — classify transcript + diff; never check off a task
- `boot-dash` — bootstrap, ports, degraded modes

## Boot

```text
cd tools/status-dash
bun run bootstrap && bun run dev
```

Reading surface (local): `http://127.0.0.1:8787`

- `GET /` overview
- `GET /specs/:slug` one writing
- `GET /constitution`
- `POST /api/chat` visuals
- `POST /api/task` checkbox write
- `GET /health`

Personal identity and preferences stay in a separate vault. Not here.
