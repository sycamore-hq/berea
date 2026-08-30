---
name: boot-dash
description: Bootstrap and run the local Reading (status dash) with no interactive prompts. Use when the dash is missing, ports fail, Melange or specify is absent, or the human says boot the dash, start the reading, or degraded mode.
---

# Boot dash

The Reading is local. No accounts. No cloud PM tool.

## Happy path

```text
cd tools/status-dash
bun run bootstrap && bun run dev
```

Reading: `http://127.0.0.1:8787`

- `GET /` overview
- `GET /specs/:slug` one writing
- `GET /constitution`
- `POST /api/chat` visuals
- `POST /api/task` checkbox write
- `GET /health`

`PROJECT_ROOT` from `SPEC_ROOT`, else `../..`, else cwd.
Port from `$PORT`, else 8787.

## Bootstrap must

1. `bun install`
2. `mkdir -p .dash`
3. apply migrations
4. if `specs/` missing, create it empty
5. if constitution missing, write the stub that says replace via
   spec-kit constitution
6. `bun run index`
7. write `.dash/BOOTSTRAP.md`
8. exit 0 unless sqlite migration failed

No prompts. No undocumented env vars.

## Degraded

| Missing | Still do |
|---|---|
| `specify` CLI | operate on the files |
| Melange / opam | run committed `_generated/` JS |
| empty `specs/` | `/health` explicit empty, pages render |
| no LLM key | deterministic chat router in the dash prompt |

Do not require Markplane, Pinto, Docker-as-only-path, or a second
backlog format.

## Stop

Bootstrap is not the place to design features. If the dash prompt in
`docs/prompts/initial-status-dash.md` disagrees with running code,
believe the prompt until the human changes it.

## Gotchas

- Binding to localhost only when the script says `0.0.0.0`.
- Inventing env vars so boot can "be flexible."
- Starting the dash from the wrong `PROJECT_ROOT` and indexing
  an empty tree.
