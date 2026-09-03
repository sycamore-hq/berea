# Tasks: memory notes as reviewed facts

**Input**: spec.md, plan.md

Each task carries the evidence it was written from.

## Phase 1: Writings

- [x] T010 Amend `spec.md` with user-visible behavior, acceptance, and
      non-goals (003 T070 owns the first real note). Then this plan and
      this file. `bun run index`. Done when INDEX lists this slug as
      planned, not specified 0/0.

## Phase 2: Reviewed is a calculation

- [x] T020 Status is parsed, not defaulted. Replace
      `normalize_status` (`memory_ml.ml:43-48`) with `status_of_string`
      returning `status option`. Missing or unknown is `None`, never
      `Active`. `note.status` becomes `status option`. Done when a note
      with no `status:` key is not `Active`.

- [x] T030 `is_reviewed`: `Active` and kind
      `Decision | Regression | Convention`. Deny-closed on every other
      pair. `load_memory_notes` keeps `note_status` and drops notes that
      fail `is_reviewed` (unless `include_sessions` keeps a session on
      the path filter). FTS and `/memory` call the default load. Done
      when a `status: proposal` under `decisions/` is not loaded.

## Phase 3: Surfaces and pins

- [x] T040 [P] `bun run check` pins the calculations and the live
      routes. Session unique token absent from `/memory` and
      `/api/memory`. Proposal / rejected / superseded / missing status
      not reviewed. Active convention reviewed and returned by FTS.
      Done when those asserts fail if `is_reviewed` is inverted.

- [x] T050 [P] `/memory` shows kind · status · as_of on each reviewed
      note. Empty copy unchanged. Done when the live `/memory` page
      contains `active` for the fixture convention.
