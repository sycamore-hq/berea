# Plan: memory notes as reviewed facts

**Stack**: the existing Melange domain and `bun:sqlite` FTS. No new
dependencies.

**Verified against** the tree at `bb4457e`. 001 already shipped the
trees, the parser, `/memory`, and FTS that skips sessions. 003 T070
placed the first real house note. 002 closes the hole where status is
a lie.

## Constitution Check

- [x] I. The writings are the work — FTS stays an overlay; checkboxes
      stay in this `tasks.md`
- [x] II. If it isn't in the files, it isn't so — a note without
      `status: active` is not a fact
- [x] III. Task status is the checkbox
- [x] IV. Feature status is derived
- [x] V. Memory is reviewed — T030 is the code gate that matches the
      article; the human merge stays in `curate-memory`
- [x] VI. Skills are procedures — no new skill
- [x] VII. Local, zero-touch — same `bun run check`
- [x] VIII. Horizon is optional frontmatter — this writing has none;
      status derives

## Citations (the gap)

- `memory_ml.ml:43-48` `normalize_status` defaults missing/unknown to
  `Active`
- `load_tree.ml:26-32` `memory_note` drops `status`
- `memory_ml.ml:77-86` `should_index` is path-only, so a
  `status: proposal` under `decisions/` is indexed
- `check_ml.ml:332-337` asserts the memory *visual*, not that FTS
  found the fixture or excluded a non-reviewed note
- `003-harness-and-hygiene#T070` owns the first real note. This plan
  does not place one.

## Order

```
T010 spec acceptance
  └─ T020 check pins (fail against the current tree)
       └─ T030 status is optional; is_reviewed deny-closed
            └─ T040 load + FTS + /memory make the pins green
```

T020 is the contract. It lands before the domain change so an
implementor can see the pins fail, then turn them green. `src/` and
`_generated/` stay one commit.

## Notes

- `include_sessions` stays a path escape. Default load is reviewed
  notes only.
- `overlay.ml:185` still hardcodes `hit_status = "active"`. That is
  true by construction: `rebuild.ml` fills `memory_fts` from
  `load_memory_notes` with the default load, so every hit is
  `Active`. Not a remaining gap.
- Do not place a note under `memory/regressions/` here. That is T070.
