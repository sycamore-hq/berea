# Tasks: memory notes as reviewed facts

**Input**: spec.md, plan.md

Each task carries the evidence it was written from. Check it before trusting
this file.

## Phase 1: Writings

- [x] T010 Amend `spec.md` with user-visible behavior, acceptance, and
      non-goals (003 T070 owns the first real note). Then this plan and
      this file. `bun run index`. Done when INDEX lists this slug as
      planned, not specified 0/0.

## Phase 2: Pins first

- [x] T020 Write the `bun run check` pins that define done. Session
      unique token absent from `/memory` and `/api/memory`. Proposal /
      rejected / superseded / missing status not reviewed. Active
      convention reviewed and returned by FTS. `/memory` shows kind ·
      status · as_of on a reviewed note. Done when those asserts exist
      in `check_ml.ml` and fail against the current tree (status
      defaults to Active; load is path-only; `/memory` omits status).

## Phase 3: Make the pins green

- [ ] T030 Status is parsed, not defaulted. Replace
      `normalize_status` (`memory_ml.ml:43-48`) with `status_of_string`
      returning `status option`. Missing or unknown is `None`, never
      `Active`. `note.status` becomes `status option`. `is_reviewed`:
      `Active` and kind `Decision | Regression | Convention`. Deny-closed
      on every other pair. Done when the unit pins in T020 pass.

- [ ] T040 `load_memory_notes` keeps `note_status` and drops notes that
      fail `is_reviewed` (unless `include_sessions` keeps a session on
      the path filter). FTS and `/memory` call the default load.
      `/memory` shows kind · status · as_of. Empty copy unchanged.
      Done when the live-route pins in T020 pass and `bun run check`
      is green.
