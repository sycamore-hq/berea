#!/usr/bin/env bash
# Idempotent Cloud Agent install. Runs from the repository root after checkout.
set -euo pipefail

export PATH="${HOME}/.bun/bin:/usr/local/bin:${PATH}"

if command -v opam >/dev/null 2>&1; then
  eval "$(opam env)"
fi

if ! command -v bun >/dev/null 2>&1; then
  echo "berea install: bun is not on PATH" >&2
  exit 1
fi

cd tools/status-dash
bun install
