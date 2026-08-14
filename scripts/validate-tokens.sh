#!/usr/bin/env bash
# validate-tokens.sh --- DTCG token validator (POSIX shell wrapper)
#
# Delegates to validate-tokens.ps1 via pwsh when available, otherwise
# falls back to JSON-only validation (jq). Full contrast and reference
# checks require PowerShell (pwsh).
#
# See specs/01-token-system.spec.md s6 and scripts/validate-tokens.ps1.

set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || { echo "Run inside a git repository" >&2; exit 1; }
TOKENS_DIR="${1:-$REPO_ROOT/tokens}"
STATUS=0

[ -d "$TOKENS_DIR" ] || { echo "tokens/ not found — skipping."; exit 0; }

# Prefer pwsh for full validation (contrast gate, reference resolution).
if command -v pwsh >/dev/null 2>&1; then
    exec pwsh -NonInteractive -File "$REPO_ROOT/scripts/validate-tokens.ps1" "$TOKENS_DIR"
fi

# Fallback: JSON validity + basic DTCG $type check only (no contrast gate).
echo "validate-tokens: pwsh not found; running JSON-only checks (no contrast gate)."
echo "Install PowerShell (pwsh) for full WCAG 2.2 contrast validation."

ALLOWED_TYPES="color dimension fontFamily fontWeight duration cubicBezier number shadow"

while IFS= read -r f; do
    if ! jq empty "$f" 2>/dev/null; then
        echo "::error file=${f}::Invalid JSON"
        STATUS=1
        continue
    fi
    # Check all $type values are in the allowed set
    while IFS= read -r t; do
        [ -z "$t" ] && continue
        found=false
        for allowed in $ALLOWED_TYPES; do
            [ "$t" = "$allowed" ] && found=true && break
        done
        if [ "$found" = false ]; then
            echo "::error file=${f}::Unknown \$type: $t"
            STATUS=1
        fi
    done < <(jq -r '.. | objects | .["$type"] // empty' "$f" 2>/dev/null)
done < <(find "$TOKENS_DIR" -type f -name '*.tokens.json' | sort)

if [ "$STATUS" -eq 0 ]; then
    echo "validate-tokens: JSON checks passed (install pwsh for full validation)."
fi
exit "$STATUS"
