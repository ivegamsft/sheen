#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || { echo "Run inside a git repository" >&2; exit 1; }
cd "$REPO_ROOT"

if command -v pwsh >/dev/null 2>&1; then
  if [ "${1:-}" = "--check" ]; then
    exec pwsh -NonInteractive -File scripts/build-system-atlas.ps1 -Check
  fi
  exec pwsh -NonInteractive -File scripts/build-system-atlas.ps1
fi

echo "pwsh is required to run scripts/build-system-atlas.ps1" >&2
exit 1
