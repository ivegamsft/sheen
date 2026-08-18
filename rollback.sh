#!/usr/bin/env bash
# rollback.sh --- basecoat-sheen consumer rollback (POSIX shell)
#
# Reverts the last sync by removing exactly the files/directories recorded in
# .sheen/manifest.json. Consumer-authored files outside the manifest are never
# touched. Behavior-equivalent to rollback.ps1.
#
# Usage:
#   ./rollback.sh                 # revert the last sync (.sheen/manifest.json)
#   ./rollback.sh path/to/manifest.json
#
# See specs/06-consumption-sync.spec.md §3.

set -euo pipefail

command -v git >/dev/null 2>&1 || { echo "git is required" >&2; exit 1; }
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || { echo "Run this inside a git repository" >&2; exit 1; }

MANIFEST="${1:-$REPO_ROOT/.sheen/manifest.json}"
[ -f "$MANIFEST" ] || { echo "No manifest found at $MANIFEST --- nothing to roll back." >&2; exit 1; }

# Extract the "files" array entries (quoted strings) without a JSON dependency.
FILES="$(awk '
  /"files"[[:space:]]*:/ { infiles=1; next }
  infiles && /\]/ { infiles=0 }
  infiles {
    line=$0
    gsub(/[[:space:]]/,"",line)
    gsub(/,$/,"",line)
    gsub(/^"/,"",line); gsub(/"$/,"",line)
    if (line != "") print line
  }
' "$MANIFEST")"

REMOVED=0
if [ -n "$FILES" ]; then
  while IFS= read -r rel; do
    [ -n "$rel" ] || continue
    path="$REPO_ROOT/$rel"
    if [ -e "$path" ]; then
      # New manifests record files only. For compatibility with older manifests that
      # recorded directories, never recursively delete directories (can remove
      # consumer-authored files created after sync).
      if [ -d "$path" ]; then
        [ -z "$(ls -A "$path" 2>/dev/null)" ] && rmdir "$path" || true
        continue
      fi
      rm -f "$path"
      REMOVED=$((REMOVED + 1))
      parent="$(dirname "$path")"
      while [ "$parent" != "$REPO_ROOT" ] && [ -d "$parent" ] && [ -z "$(ls -A "$parent")" ]; do
        rmdir "$parent"
        parent="$(dirname "$parent")"
      done
    fi
  done <<EOF
$FILES
EOF
fi

rm -f "$MANIFEST"
SHEEN_DIR="$REPO_ROOT/.sheen"
[ -d "$SHEEN_DIR" ] && [ -z "$(ls -A "$SHEEN_DIR")" ] && rmdir "$SHEEN_DIR"
echo "rollback: removed $REMOVED item(s)."
