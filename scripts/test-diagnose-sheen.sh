#!/usr/bin/env bash
set -euo pipefail

if command -v pwsh >/dev/null 2>&1; then
  exec pwsh -NoLogo -NoProfile -File scripts/test-diagnose-sheen.ps1
fi

echo "pwsh is required to run scripts/test-diagnose-sheen.ps1" >&2
exit 2
