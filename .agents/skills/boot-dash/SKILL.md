---
name: boot-dash
description: Bootstrap and run the local Reading (status dash) with no interactive prompts. Use when the dash is missing, ports fail, Melange or specify is absent, or the human says boot the dash, start the reading, or degraded mode.
---

# Boot dash

The Reading is local. No accounts. No cloud PM tool.

```text
cd tools/status-dash
bun run bootstrap && bun run dev
```

No prompts. Exit 0 unless the SQLite migration failed.

Reading: `http://127.0.0.1:8787`. Host is `0.0.0.0`.

## Env (the only ones)

| Variable | Default | Meaning |
|---|---|---|
| `SPEC_ROOT` | `../..` from `tools/status-dash`, else cwd | Product repo root |
| `PORT` | `8787` | Hono bind port |

No undocumented env vars. Do not invent one so boot can "be flexible."

## Scripts

| Script | Does |
|---|---|
| `bun run bootstrap` | The list below |
| `bun run dev` | Serve |
| `bun run index` | Rebuild context + `specs/INDEX.md` + FTS |
| `bun run check` | Deterministic checks against `fixtures/` |
| `bun run build` | `dune build @melange` — regenerates `_generated/` |

## What bootstrap does

1. `bun install`
2. `mkdir -p $SPEC_ROOT/.dash`
3. Apply `overlay/migrations/`
4. If `specs/` missing, create it empty
5. If `.specify/memory/constitution.md` missing, write the stub that
   says replace via spec-kit constitution
6. `bun run index`
7. Write `.dash/BOOTSTRAP.md`

## Degraded

| Missing | Mode |
|---|---|
| Melange / opam | Run committed `_generated/` JS |
| `specify` CLI | Parse the files anyway |
| Empty `specs/` | `/health` reports `empty-specs`; pages still serve |
| Stale context | Banner on `/`; `POST /api/sync` rebuilds |
| No LLM key | Deterministic chat router |

Do not require Markplane, Pinto, Docker-as-only-path, or a second
backlog format.

SQLite at `$SPEC_ROOT/.dash/dash.sqlite`. Gitignored. Rebuildable.

## Stop

Bootstrap is not the place to design features. If the writings and the
running code disagree, say so and stop. Do not patch one to match the
other from this skill.

## Gotchas

- Binding to localhost only when the script says `0.0.0.0`.
- Starting the dash from the wrong `SPEC_ROOT` and indexing an empty tree.
- Committing `.dash/`. It is derived.
