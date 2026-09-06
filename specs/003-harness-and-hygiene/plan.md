# Plan: harness and hygiene

**Stack**: no new dependencies. GitHub Actions for the gate, the existing
Melange/Bun toolchain for everything else.

**Verified against** the tree at `70a6a3f`. Every claim in `spec.md` was read
off disk; the citations live beside each task.

## Constitution Check

- [x] I. The writings are the work — T040 removes the second source of truth
      rather than adding a third
- [x] II. If it isn't in the files, it isn't so — T020 makes the committed
      `_generated/` tree checkable instead of assumed
- [x] III. Task status is the checkbox — T020 is what gives the checkbox
      teeth; nothing here introduces a parallel status
- [x] IV. Feature status is derived — T060 fixes a derivation, in the
      derivation, not by editing a writing
- [x] V. Memory is reviewed — T070 walks the proposal-then-merge gate as
      written; the action agent appends to `memory/sessions/` only
- [x] VI. Skills are procedures — T030 either wires them or says plainly that
      a human must name the file
- [x] VII. Local, zero-touch — CI runs the same two commands a human runs
- [x] VIII. Horizon is optional frontmatter — T060 amends the article:
      derived `Done` outranks explicit frontmatter. A finished spec is later.

## Order

T020 comes first because it is what turns every later item from a promise
into something enforced. The rest are independent and can be taken in any
order.

```
T020 CI
  ├─ T030 wire the skills
  ├─ T040 fold the stray prompt
  ├─ T050 reading-surface is not an example
  ├─ T060 horizon expires
  ├─ T070 walk the memory loop
  ├─ T080 one slug predicate
  └─ T090 the tail of speckit.ml
```

T050 and T080 touch the same predicate from opposite sides: T050 renames the
fixture, T080 tightens what counts as a slug. Whichever lands second has to
confirm both `specs/` and the fixture still load.

T030 and T060 both change what an agent sees on a morning turn. Do them
before trusting a morning turn again.

## Notes

- `src/` and `_generated/` are one commit, always. That contract is the whole
  point of T020.
- `.dash/` is gitignored, so regenerating it changes nothing in git.
  `specs/INDEX.md` *is* committed and does show up in `git diff --exit-code`.
- Every task that touches `specs/` ends in `bun run index`.
- The local switch is ocaml 5.5.x (5.5.0 today), dune 3.24.2, melange
  7.0.1-55, ocamlformat 0.29.0. Melange ships one build per OCaml minor
  line (`7.0.1-51` … `7.0.1-55`, plus `7.0.1-414`); `7.0.1-55` constrains
  ocaml `{>= "5.5" & < "5.6"}`, so the next compiler bump waits on a
  Melange tag for that line. T020 generates `status_dash.opam` from
  `dune-project` and pins those versions.
