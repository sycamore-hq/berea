# Tasks: harness and hygiene

**Input**: spec.md, plan.md

Each task carries the evidence it was written from. Check it before trusting
this file.

## Phase 1: Land what was in flight

- [x] T000 Land the encoding fix: hand bytes to the runtime as bytes, not as
      text it encodes twice (`js_shims.ml` `Buf` + latin1 fs, `hono.ml`
      `c.body`/`req.arrayBuffer`, `app.ml` `bytes_resp`, `overlay.ml`).
      Done when `git diff --exit-code` is clean after a fresh
      `dune build @melange`, `bun run check` passes, and no file in `specs/`
      or `.dash/` holds the bytes `c3 a2 c2 80`.
- [x] T010 Promote the staging plan into `specs/003-harness-and-hygiene/` and
      delete `docs/plans/`. Git holds the history.

## Phase 2: The gate

- [ ] T020 CI: one job running `dune build @melange && git diff --exit-code
      && bun run check`, on push and PR. Needs `setup-ocaml` plus
      `oven-sh/setup-bun`, a cached opam switch, and either
      `(generate_opam_files true)` with a depends stanza or pinned versions —
      `dune-project` declares the package but generates no `.opam`, and
      `_opam/` is gitignored. Add `dune build @fmt` only if `src/` is already
      clean under it. Done when a deliberate edit to one `.ml` file without a
      rebuild turns the job red.

## Phase 3: Say what is true

- [ ] T030 Wire the skills or drop the shape. Nine `SKILL.md` files carry
      trigger-packed `description:` frontmatter whose only purpose is harness
      dispatch, and `ls -d .claude` finds nothing. Either symlink
      `.claude/skills/<name>` → `../../.agents/skills/<name>`, keeping
      `.agents/` canonical, or strip the frontmatter and have `AGENTS.md` and
      `LOOPS.md` name the exact file to read at each point in the day. Verify
      a skill actually loads before calling this done. Either way
      `AGENTS.md:20` and its `## Skills` section must then describe what is
      true.
- [ ] T040 Fold `docs/prompts/initial-status-dash.md` into the writings, then
      `git rm` it. 548 lines, `## Non-negotiables` at :53 covering the same
      ground as the constitution's eight articles, and it is not in the
      Writings list at `AGENTS.md:14-22`. Rules go to the constitution,
      design goes to 001's `spec.md`/`plan.md`, superseded material stays in
      git. Done when no file outside the Writings list states a rule about
      how this repo works.
- [ ] T050 `001-example` is not an example — it is the spec for the shipped
      reading surface, and `tools/status-dash/fixtures/specs/001-example/`
      uses the identical slug. Rename to `specs/001-reading-surface/`, rename
      the fixture to something no one could mistake for a writing, update the
      four literal `join4` paths at `check_ml.ml:58-60,208-212`, then
      `bun run index`. Done when `grep -rn "001-example" .` returns nothing
      outside `.git/`.

## Phase 4: Fix the derivations

- [ ] T060 Explicit horizon must expire. `speckit.ml:630 infer_horizon`
      returns `Some h` unconditionally, so `001-example` — status `done`,
      twelve of twelve boxes checked — sits alone on the Now horizon and is
      the only answer the dash offers to the morning question. Match on
      `status` first so `Done` yields `Later` whatever the frontmatter says.
      Fix it in the derivation, not by editing the writing; if this
      contradicts Article VIII, amend the article in the same change. Done
      when `specs/INDEX.md` shows the reading-surface spec as `done | later`,
      `.dash/context/summary.md` reports an empty Now horizon, and a test in
      `check_ml.ml` pins `Done + horizon: now → Later`.
- [ ] T080 One slug predicate, in Domain. `domain.ml:180 is_feature_slug`
      (`n >= 5`, word chars throughout) has no callers; `load_tree.ml:62
      is_spec_dir` (`n >= 4`, accepts a bare `001-`) is the one actually
      filtering `specs/`. Keep the Domain one, have `load_tree` call it,
      delete `is_spec_dir`. Delete `domain.ml:195 task_of_feature`, a
      one-line accessor with no callers. Done when one predicate exists, it
      lives in `domain.ml`, `bun run check` passes, and `/` still lists every
      spec plus the fixture.
- [ ] T090 The tail of `speckit.ml`. `:745-746` closes `set_task_done` with
      `;;` and then a second bare `;;`, leaving `find_from` stranded at :747
      past the end of everything else — a string helper used four times from
      `markdown.ml:37,280,297,300`. Move it up with its peers, drop the stray
      `;;`, rebuild.

## Phase 5: Walk the loop

- [ ] T070 Run the memory loop once, on a real fact. `find memory -type f`
      returns a README and four `.gitkeep`s: `curate-memory`, the
      proposal-under-`sessions/` step, the human merge and the `memory:`
      commit prefix have never been exercised. T000's encoding bug is a
      textbook `memory/regressions/` entry — a real failure, a diagnosed
      cause, a rule that prevents the repeat: *Melange strings are byte
      strings; every boundary out of the program must hand over bytes, never
      text the runtime re-encodes.* Point at `js_shims.ml` and `hono.ml`; do
      not copy the code in. Done when one file exists under
      `memory/regressions/`, it arrived through proposal-then-merge rather
      than being hand-placed, and whatever the loop got wrong is recorded.
      That friction is the actual deliverable.
