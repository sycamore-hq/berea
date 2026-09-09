# Tasks: OCaml 5.5 toolchain

**Input**: spec.md, plan.md

Each task carries the evidence it was written from. Check it before trusting
this file.

## Phase 1: Writings

- [x] T010 This spec, this plan, this file. `bun run index`. Done when
      INDEX lists `004-ocaml-55` as planned, not specified 0/0.

## Phase 2: Pins

- [x] T020 Pin the switch the compiler reads. `dune-project` depends:
      ocaml 5.5.1, dune 3.24.2, melange 7.0.1-55. Regenerate
      `status_dash.opam`. CI already has `ocaml-compiler: 5.5.1` (#18);
      keep `--with-dev-setup` and `gc.autoDetach false`. After
      `opam env`, print `opam --version`, `ocaml -version`, and
      `dune --version`, and fail unless ocaml is 5.5.1. Done when
      those files agree on 5.5.1 and a 5.2.0 / range pin is gone
      from `dune-project` and `.opam`.

## Phase 3: Prove the switch

- [x] T030 On ocaml 5.5.1 + melange 7.0.1-55, `dune build @melange`,
      copy `src/` and replace `_generated/node_modules`,
      `git diff --exit-code` after that copy, `bun run check`.
      Commit any JS the 5.5.1 stdlib emits with the `.ml`. Same
      contract as `003-harness-and-hygiene#T020`.

## Phase 4: Writings agree

- [x] T040 Amend `specs/003-harness-and-hygiene/plan.md` Notes so it
      keeps 5.5.1 / opam 2.5 / `:with-dev-setup` and points at this
      slug for the exact pin and the proved JS. Keep the
      Melange-per-minor-line rule. Also
      `tools/status-dash/README.md`: ocaml 5.5.1 and
      `opam switch create . 5.5.1 --deps-only`. `bun run index`.
      Done when no writing names 5.5.0 or 5.2.0 as the current
      switch.
