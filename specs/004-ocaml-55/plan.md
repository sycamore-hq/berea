# Plan: OCaml 5.5 toolchain

**Stack**: ocaml 5.5.1, dune 3.24.2, melange 7.0.1-55, ocamlformat
0.29.0, opam 2.5.2. No new product dependencies. `setup-ocaml@v3`
tracks the current released opam (2.5.2 as of this writing; no
`opam-version` input on v3).

**Verified against** `7079c49` (main after #18). 003 T020 owns the pin
shape. #15 moved the pins to a 5.5 range. #18 named 5.5.1 in CI, the
003 note, and the README switch-create. They did not pin the 5.5.1
patch in `dune-project` or rebuild `_generated/` on that switch.

## Constitution Check

- [x] I. The writings are the work — this slug is the exact pin and
      the proved JS; 003 stays the hygiene feature that invented the
      pins
- [x] II. If it isn't in the files, it isn't so — T020 tightens the
      pin the compiler reads; T030 is the JS; T040 makes the 003 note
      point here
- [x] III. Task status is the checkbox
- [x] IV. Feature status is derived
- [x] V. Memory is reviewed — no new note
- [x] VI. Skills are procedures — no new skill
- [x] VII. Local, zero-touch — CI still runs `dune build @melange`
      then `bun run check`
- [x] VIII. Horizon is optional frontmatter — `now` until done

## Citations (the gap on `7079c49`)

- `tools/status-dash/dune-project:12-15` pins ocaml
  `(and (>= 5.5.0) (< 5.6))`, dune 3.24.2, melange 7.0.1-55,
  ocamlformat 0.29.0 `:with-dev-setup`
- `tools/status-dash/status_dash.opam:5-10` is the generated copy
  (range + ocamlformat + odoc)
- `.github/workflows/check.yml:30` `ocaml-compiler: 5.5.1`; L36
  `--with-dev-setup`; L47–49 copy only `_generated/src`
- `tools/status-dash/README.md:14-16` names ocaml 5.5.x and
  `opam switch create . 5.5.1 --deps-only`
- `specs/003-harness-and-hygiene/plan.md:58-64` names 5.5.x
  (5.5.1 today) and the Melange-per-minor-line rule

## Order

```
T010 writings
  └─ T020 pins (dune-project, .opam; CI already 5.5.1)
       └─ T030 rebuild _generated/ on 5.5.1
            └─ T040 003 plan note points at this slug
```

`src/` and `_generated/` stay one commit (003 T020). T030 is that
commit for any JS the 5.5.1 stdlib emits.

## Notes

- Pin the patch: 5.5.1, not a 5.5 range. 5.5.0 is the release with
  the type-system and Marshal/bytecode holes.
- Melange 7.0.1-55 constrains ocaml `{>= "5.5" & < "5.6"}`. The next
  compiler minor waits on a Melange tag for that line. That rule
  stays in the 003 note.
- Dune 3.24.2 and ocamlformat 0.29.0 are already current. ocamlformat
  stays in `dune-project` gated on `:with-dev-setup` (003 note); `@fmt`
  is still not part of CI. CI keeps `--with-dev-setup` from #18.
- `setup-ocaml@v3` installs the current released opam. Print
  `opam --version` in CI so a silent 2.4 is visible. Do not invent an
  `opam-version` input the action does not have.
- Do not rewrite 003's tasks. Amend the plan note only.
- Copy `_generated/node_modules` by replacing the tree
  (`rm -rf` then `cp -a`) so a stdlib module the build stops emitting
  turns `git diff --cached` red.
