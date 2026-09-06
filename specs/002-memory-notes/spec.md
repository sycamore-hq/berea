# Memory notes as reviewed facts

Facts that are not constitution and not a spec live under `memory/` with
frontmatter. Personal vault stays out.

## Why

Agents need a place for regressions and conventions without stuffing
`AGENTS.md` or copying the constitution. A note is a fact only after
review. A session file is a proposal, not canon.

## Scope

- Frontmatter schema already in `memory/README.md`
- Review gate (curator proposes, human merges) — constitution V
- FTS, `/memory`, and chat memory search the same reviewed set

Reviewed means: `status: active` and a path under `decisions/`,
`regressions/`, or `conventions/`. Sessions, proposals, rejected,
superseded, missing or unknown status, and notes outside those trees
are not facts.

## Out of scope

- Walking the loop on a real house fact (`003-harness-and-hygiene#T070`)
- Browser edit UI (001)
- Personal identity or preferences (separate vault)
- Copying constitution or spec bodies into `memory/`

## User stories

1. An agent asks about a convention. FTS and the memory visual return
   only active reviewed notes.
2. A session proposal with a unique token does not appear on `/memory`
   or in `/api/memory`.
3. `/memory` lists reviewed notes with kind and status. When none exist,
   the empty copy still points at `memory/sessions/` and the curator.

## Acceptance

- `bun run check` pins: session skipped; proposal / rejected /
  superseded / missing status not reviewed; an active convention is
  reviewed and found by FTS
- `/memory` lists only reviewed notes and shows kind · status · as_of
- The review gate stays in the writings. This feature does not invent
  a second board or a browser merge

See also [[001-reading-surface]], [[003-harness-and-hygiene]].
