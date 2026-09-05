---
as_of: 2026-09-05
supersedes:
source: spec:003-harness-and-hygiene
confidence: high
status: active
---

# Melange strings are byte strings

Every boundary out of the program must hand over bytes, never text the
runtime re-encodes.

`specs/INDEX.md` once shipped an em dash as `c3 a2 c2 80` because
Melange compiles an OCaml string literal to a JS string with one code
unit per byte, and four boundaries then encoded that as UTF-8 again.

Point at `tools/status-dash/src/js_shims.ml` and
`tools/status-dash/src/hono.ml`. Do not copy the code.

Arrived from `memory/sessions/2026-09-05-utf8-byte-boundaries.md`.
The first walk had no separate curator: Action wrote the proposal,
this merge is the implement of T070. That two-role gap is the
friction. Next walk, keep them split.
