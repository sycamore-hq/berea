---
as_of: 2026-09-05
supersedes:
source: spec:003-harness-and-hygiene
confidence: high
status: proposal
---

# Proposal: Melange strings are byte strings

T000's encoding bug. INDEX.md shipped an em dash encoded twice because
Melange compiles an OCaml string literal to a JS string with one code
unit per byte, and four boundaries then encoded that as UTF-8 again.

Rule: Melange strings are byte strings. Every boundary out of the
program must hand over bytes, never text the runtime re-encodes.

Point at `tools/status-dash/src/js_shims.ml` (latin1 fs, `Buf`) and
`tools/status-dash/src/hono.ml` (`c.body`, `req.arrayBuffer`). Do not
copy the code.

Promote to `memory/regressions/` on merge. Status stays `proposal`
until then.

## Friction on this first walk

Action may only append `sessions/`. There is no curator bot and no
separate human in this turn — the implement of T070 is what promotes
the note. That is the loop's real gap: proposal-then-merge assumes two
roles, and a solo close has to play both. Recorded so the next walk
does not pretend otherwise.
