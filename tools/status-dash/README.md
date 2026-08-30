# Reading surface

Local dashboard + chat over this repo's Spec Kit writings.

```text
bun run bootstrap && bun run dev
```

http://127.0.0.1:8787 — no accounts. Files are the database.

`SPEC_ROOT` (else `../..`) is the product repo. `PORT` defaults to 8787.

The domain, views, server, and bootstrap are OCaml, compiled to JS with
Melange (`opam install dune melange` once, then `bun run build`). The
committed `_generated/` output runs as-is, so Melange is optional to boot.
If `specify` is missing, the files still parse. SQLite at
`$SPEC_ROOT/.dash/dash.sqlite` is derived: pins, FTS, chat. Never a
second backlog.
