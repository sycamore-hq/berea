# Cursor Cloud (Berea)

Pins match `specs/003-harness-and-hygiene/plan.md`: OCaml 5.5.x (5.5.0
today), dune 3.24.2, Melange 7.0.1-55, ocamlformat 0.29.0, bun 1.4.2.

Agents whose selected repo is Berea use `environment.json` + `Dockerfile`.
Multi-repo agents started from another workspace keep that workspace's
dashboard environment, and a dashboard-saved environment for Berea
overrides this file; delete it if one exists.

After checkout, `install` runs `install.sh` (`bun install --frozen-lockfile`
in `tools/status-dash`). Boot the Reading as under Boot in `AGENTS.md`.
