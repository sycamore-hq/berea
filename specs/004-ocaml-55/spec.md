---
horizon: now
priority: high
---

# OCaml 5.5 toolchain

The house must compile, regenerate, and check on the current released
OCaml 5.5 patch, with the Melange build that exists for that line.
Naming 5.5.1 in CI is not the same as pinning it in `dune-project` or
proving the committed `_generated/` tree on that switch.

## Why

Article II: if it isn't in the files, it isn't so. `003-harness-and-hygiene`
T020 made `dune-project` / `status_dash.opam` and CI the pins the build
uses. On `7079c49` (#18) those writings and CI already name **5.5.1**,
but `dune-project` still pins a 5.5 range (`>= 5.5.0` and `< 5.6`) and
the committed Melange stdlib JS was produced on 5.5.0. 5.5.0 still has
the type-system and Marshal/bytecode holes, so this slug pins the patch
exactly and makes the committed `_generated/` tree prove it.

OCaml 5.5.1 is the current 5.5 release. Melange 7.0.1-55 is the 5.5
build. Dune 3.24.2, ocamlformat 0.29.0, and opam 2.5.2 are already
current. #15 landed the 5.5 stack; #18 named the 5.5.1 patch in CI
and the 003 note.

Until `dune-project` pins that patch and `_generated/` is produced on
that switch, the house is not proven on 5.5.1.

## Scope

- The compiler pin the opam file actually constrains
- The committed `_generated/` JS on that switch
- CI copies the Melange stdlib tree, not only `src/*.js`
- Writings that name the switch agree with those pins

## Out of scope

- Adopting 5.5-only syntax
- Rewriting the reading surface
- A second backlog or a new skill
- Cutting tags on other remotes
- Re-landing the 5.5 stack (#15) or the 5.5.1 name in CI (#18)

## User stories

1. A contributor installs from `status_dash.opam` and gets OCaml 5.5.1,
   not whichever 5.5.x opam picks inside the range.
2. CI turns red if `_generated/node_modules/melange` was produced on
   the old compiler.
3. The 003 plan note points at this slug for the exact pin and the
   proved JS.

## Acceptance

- `dune-project` and the generated `status_dash.opam` pin ocaml 5.5.1,
  dune 3.24.2, and melange 7.0.1-55
- CI initialises 5.5.1, installs deps (including `--with-dev-setup`),
  prints the toolchain, and fails unless ocaml is 5.5.1
- After `dune build @melange` and the copy of `src/` plus
  `node_modules/` into `_generated/`, `git diff --exit-code` is clean
- `bun run check` passes
- Writings that name the switch say 5.5.1, not 5.5.0 or 5.2.0, as the
  current compiler

See also [[003-harness-and-hygiene]].
