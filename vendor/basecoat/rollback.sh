#!/usr/bin/env bash
# rollback.sh — Roll a consumer repo back to a specific BaseCoat release tag.
#
# Run from the root of a consumer repository.
#
# Usage:
#   BASECOAT_REPO=https://github.com/my-org/basecoat.git bash rollback.sh v3.25.0
#   bash rollback.sh v3.25.0
#   bash rollback.sh            # show current version and recent tags
#
# Environment variables:
#   BASECOAT_REPO        HTTPS clone URL of the BaseCoat repo (required)
#   BASECOAT_TARGET_DIR  Directory in consumer repo (default: .github/base-coat)

set -euo pipefail

SOURCE_REPO="${BASECOAT_REPO:-https://github.com/YOUR-ORG/basecoat.git}"
TARGET_DIR="${BASECOAT_TARGET_DIR:-.github/base-coat}"
TAG="${1:-}"

if ! command -v git >/dev/null 2>&1; then
  echo "git is required" >&2
  exit 1
fi

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || true)"
if [[ -z "$REPO_ROOT" ]]; then
  echo "Run this inside a git repository" >&2
  exit 1
fi

FULL_TARGET="${REPO_ROOT}/${TARGET_DIR}"

# ── Show current version and available tags if no tag given ──────────────────

if [[ -z "$TAG" ]]; then
  VERSION_FILE="${FULL_TARGET}/version.json"
  CURRENT="unknown"
  if [[ -f "$VERSION_FILE" ]] && command -v jq >/dev/null 2>&1; then
    CURRENT="$(jq -r '.version // "unknown"' "$VERSION_FILE")"
  elif [[ -f "$VERSION_FILE" ]]; then
    CURRENT="$(grep -o '"version"[[:space:]]*:[[:space:]]*"[^"]*"' "$VERSION_FILE" | head -1 | grep -o '"[^"]*"$' | tr -d '"')"
  fi
  echo "Current BaseCoat version: v${CURRENT}"
  echo ""
  echo "Recent release tags:"
  git ls-remote --tags --sort='-version:refname' "$SOURCE_REPO" 'v*' 2>/dev/null \
    | grep -oP 'v[\d.]+$' \
    | head -10 \
    | sed 's/^/  /' || echo "  (could not fetch tags — check BASECOAT_REPO)"
  echo ""
  echo "Usage: bash rollback.sh <tag>"
  echo "       e.g.: bash rollback.sh v3.25.0"
  exit 0
fi

# ── Normalise tag ─────────────────────────────────────────────────────────────

[[ "$TAG" == v* ]] || TAG="v${TAG}"

# ── Show prior version ────────────────────────────────────────────────────────

VERSION_FILE="${FULL_TARGET}/version.json"
PRIOR="unknown"
if [[ -f "$VERSION_FILE" ]] && command -v jq >/dev/null 2>&1; then
  PRIOR="$(jq -r '.version // "unknown"' "$VERSION_FILE")"
elif [[ -f "$VERSION_FILE" ]]; then
  PRIOR="$(grep -o '"version"[[:space:]]*:[[:space:]]*"[^"]*"' "$VERSION_FILE" | head -1 | grep -o '"[^"]*"$' | tr -d '"')"
fi

echo "Rolling back BaseCoat: v${PRIOR}  →  ${TAG}"
echo "Source : ${SOURCE_REPO}"
echo "Target : ${FULL_TARGET}"
echo ""

# ── Clone the target tag ──────────────────────────────────────────────────────

TMP_DIR="$(mktemp -d)"
SOURCE_PATH="${TMP_DIR}/source"

cleanup() { rm -rf "$TMP_DIR"; }
trap cleanup EXIT

echo "Cloning ${TAG} from ${SOURCE_REPO} ..."
git clone --quiet --depth 1 --branch "$TAG" "$SOURCE_REPO" "$SOURCE_PATH"

# ── Sync assets ───────────────────────────────────────────────────────────────

mkdir -p "$FULL_TARGET"

for ITEM in README.md CHANGELOG.md version.json basecoat-metadata.json \
            instructions skills prompts agents docs; do
  SRC="${SOURCE_PATH}/${ITEM}"
  DST="${FULL_TARGET}/${ITEM}"
  if [[ ! -e "$SRC" ]]; then continue; fi
  rm -rf "$DST"
  cp -r "$SRC" "$DST"
done

# Backwards-compat: copy INVENTORY.md to target root
INVENTORY_SRC="${SOURCE_PATH}/docs/reference/INVENTORY.md"
if [[ -f "$INVENTORY_SRC" ]]; then
  cp "$INVENTORY_SRC" "${FULL_TARGET}/INVENTORY.md"
fi

echo ""
echo "✓ Rolled back to ${TAG} successfully."
echo "  Run 'git diff --stat' to review changes before committing."
