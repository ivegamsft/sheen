#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || { echo "Run inside a git repository" >&2; exit 1; }
cd "$REPO_ROOT"

if command -v pwsh >/dev/null 2>&1; then
  exec pwsh -NonInteractive -File scripts/lint-frontmatter.ps1
fi

echo "pwsh is required to run scripts/lint-frontmatter.ps1" >&2
exit 1
