---
horizon: now
priority: high
---

# Harness and hygiene

The house describes a way of working that the repository does not yet
enforce. Nine skills carry harness frontmatter nothing dispatches on. The
checkbox that Article III calls the status is checked by hand, and nothing
fails when `src/` and `_generated/` disagree. A 548-line prompt outside the
Writings states rules the constitution already owns. This writing closes
the gap between what the files say and what the files do.

## Why

Article II says if it isn't in the files, it isn't so. The inverse also
binds: a rule stated in a file that nothing reads is not a rule, it is
decoration. Every item here is a place where the shape exists without the
mechanism, and each one costs a future session either a wrong answer or a
silent drift.

Two of them already gave wrong answers. `specs/INDEX.md` shipped an em dash
encoded twice, because no build gate compared the emitted JS to its source.
The morning question — the whole point of the summary — answered with
the reading-surface spec, twelve of twelve boxes checked, because explicit
`horizon:` frontmatter outranked a derived `Done`.

## Scope

- A build gate that makes the committed `_generated/` tree a fact rather
  than a discipline
- Skills either wired to the harness or honestly described as manual
- One backlog: fold the stray prompt into the constitution and 001
- One slug predicate, in `domain.ml`
- Horizon derivation that expires on `Done`
- The memory loop walked once, end to end, on a real fact

## Out of scope

Rewriting the dash surfaces. New features on the reading surface. Anything
that changes what the constitution says, except where a task names the
article it must amend and amends it in the same change.

## User stories

1. A contributor edits a `.ml` file and forgets to rebuild. CI turns red
   before the mismatch reaches `main`.
2. An agent opens a fresh session in the morning and reaches `examine`
   without a human naming the path — or `AGENTS.md` tells it plainly that a
   human must.
3. An agent asks "what should we work on?" and is not offered a spec whose
   every box is checked.
4. A curator proposes a memory note, a human merges it, and `/memory`
   renders it. The loop has been walked, so its shape is known.

See also [[001-reading-surface]], [[002-memory-notes]].
