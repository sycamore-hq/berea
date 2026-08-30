# Plan: the Reading surface

**Stack**: Melange (OCaml) domain, Hono on Bun, HTML templates + small
client JS, `bun:sqlite` overlay.

**Project root**: `SPEC_ROOT`, else `../..` from `tools/status-dash`.

## Constitution Check

- [x] Writings are the work — parse spec-kit files; no second backlog
- [x] SQLite is derived — pins, FTS, chat, snapshots only
- [x] Task status is the checkbox in `tasks.md`
- [x] Memory is reviewed — no browser edit UI; sessions/ only from action
- [x] Local, zero-touch boot
- [x] Horizon is optional frontmatter on spec.md

## Layout

See `tools/status-dash/`. Domain calculations in `src/*.ml` with committed
`_generated/` JS so Melange is optional at runtime.
