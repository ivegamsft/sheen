#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="${1:-$(pwd)}"
cd "$ROOT_DIR"

if ! command -v git >/dev/null 2>&1; then
  echo "git is required" >&2
  exit 1
fi

git config core.hooksPath .githooks
chmod +x .githooks/commit-msg

echo "Configured git hooks path to .githooks"