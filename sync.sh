#!/usr/bin/env bash
# sync.sh --- basecoat-sheen consumer sync (POSIX shell)
#
# Applies the "finish coat" to the current repo: clones the upstream sheen source
# at the configured ref, resolves the .sheen.yml allow-lists, copies selected
# assets into the consumer's customization directories, and records a manifest so
# rollback.sh can revert precisely.
#
# Idempotent: re-running with the same config yields the same tree.
# Behavior-equivalent to sync.ps1.
#
# Config precedence: SHEEN_REPO / SHEEN_REF env vars > repo-root .sheen.yml > defaults.
# See specs/06-consumption-sync.spec.md.

set -euo pipefail

DEFAULT_SOURCE="https://github.com/ivegamsft/sheen.git"
DEFAULT_REF="main"

# Asset type -> consumer target directory (parallel arrays; keep in sync).
TYPES="skills agents instructions prompts templates tokens"
target_for() {
  case "$1" in
    skills)       echo ".github/skills" ;;
    agents)       echo ".github/agents" ;;
    instructions) echo ".github/instructions" ;;
    prompts)      echo ".github/prompts" ;;
    templates)    echo "sheen/templates" ;;
    tokens)       echo "sheen/tokens" ;;
  esac
}

command -v git >/dev/null 2>&1 || { echo "git is required" >&2; exit 1; }
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || { echo "Run this inside a git repository" >&2; exit 1; }
CONFIG="$REPO_ROOT/.sheen.yml"

# Scalar top-level key. Prints value or nothing.
yml_value() {
  [ -f "$CONFIG" ] || return 0
  sed -n "s/^$1:[[:space:]]*//p" "$CONFIG" | head -n1 \
    | sed 's/[[:space:]]*#.*$//' | sed 's/^"\(.*\)"$/\1/' | sed "s/^'\(.*\)'$/\1/" \
    | sed 's/[[:space:]]*$//'
}

# Allow-list. Prints "\x00" sentinel line "ALL" when key absent; otherwise one name per line.
yml_list() {
  local key="$1"
  if [ ! -f "$CONFIG" ]; then echo "__ALL__"; return 0; fi
  if ! grep -Eq "^$key:" "$CONFIG"; then echo "__ALL__"; return 0; fi
  local inline
  inline="$(sed -n "s/^$key:[[:space:]]*\[\(.*\)\][[:space:]]*$/\1/p" "$CONFIG" | head -n1)"
  if [ -n "$inline" ]; then
    echo "$inline" | tr ',' '\n' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | grep -v '^$'
    return 0
  fi
  awk -v k="$key" '
    $0 ~ "^"k":" { grab=1; next }
    grab==1 {
      if ($0 ~ /^[[:space:]]+-[[:space:]]*/) { sub(/^[[:space:]]+-[[:space:]]*/,""); sub(/[[:space:]]*#.*$/,""); sub(/[[:space:]]*$/,""); if ($0!="") print; next }
      if ($0 ~ /^[[:space:]]*#/ || $0 ~ /^[[:space:]]*$/) { next }
      grab=0
    }
  ' "$CONFIG"
}

SOURCE="${SHEEN_REPO:-$(yml_value source)}"; [ -n "$SOURCE" ] || SOURCE="$DEFAULT_SOURCE"
REF="${SHEEN_REF:-$(yml_value ref)}"; [ -n "$REF" ] || REF="$DEFAULT_REF"
DISPLAY_SOURCE="$(echo "$SOURCE" | sed -E 's#^(https?://)[^/@]*@#\1#' | sed 's/[?#].*$//')"
echo "sheen sync: $DISPLAY_SOURCE @ $REF"

WORK="$(mktemp -d "${TMPDIR:-/tmp}/sheen-sync-XXXXXX")"
cleanup() { rm -rf "$WORK"; }
trap cleanup EXIT

if ! git clone --quiet --depth 1 --branch "$REF" "$SOURCE" "$WORK" 2>/dev/null; then
  git clone --quiet "$SOURCE" "$WORK"
  git -C "$WORK" checkout --quiet "$REF"
fi
COMMIT="$(git -C "$WORK" rev-parse HEAD)"

mkdir -p "$REPO_ROOT/.sheen"
MANIFEST="$REPO_ROOT/.sheen/manifest.json"
FILES=""
COUNT=0

in_list() { # name, list-text
  [ "$2" = "__ALL__" ] && return 0
  printf '%s\n' "$2" | grep -Fxq "$1"
}

for type in $TYPES; do
  SRC_DIR="$WORK/$type"
  [ -d "$SRC_DIR" ] || continue
  ALLOW="$(yml_list "$type")"
  DEST_ROOT="$REPO_ROOT/$(target_for "$type")"
  for entry in "$SRC_DIR"/* "$SRC_DIR"/.[!.]*; do
    [ -e "$entry" ] || continue
    base="$(basename "$entry")"
    [ "$base" = ".gitkeep" ] && continue
    name="$base"
    [ -f "$entry" ] && name="${base%.*}"
    in_list "$name" "$ALLOW" || continue
    mkdir -p "$DEST_ROOT"
    if [ -d "$entry" ]; then
      rm -rf "${DEST_ROOT:?}/$base"
      cp -R "$entry" "$DEST_ROOT/$base"
    else
      cp "$entry" "$DEST_ROOT/$base"
    fi
    rel="$(target_for "$type")/$base"
    FILES="$FILES  \"$rel\",
"
    COUNT=$((COUNT + 1))
  done
done

FILES_JSON="$(printf '%s' "$FILES" | sed '$ s/,$//')"
SYNCED="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
cat > "$MANIFEST" <<EOF
{
  "schema": "sheen-manifest/v1",
  "source": "$DISPLAY_SOURCE",
  "ref": "$REF",
  "synced": "$SYNCED",
  "commit": "$COMMIT",
  "files": [
$FILES_JSON
  ]
}
EOF

echo "sheen sync: wrote ${COUNT} item(s); manifest at .sheen/manifest.json"

# Run token build if the consumer opts into materialized tokens (spec 01 §4 / spec 06 §2)
MATERIALIZE="$(yml_value 'materialize_tokens')"
if [ "$MATERIALIZE" = 'true' ]; then
  BUILD_PS="$REPO_ROOT/scripts/build-tokens.ps1"
  if command -v pwsh >/dev/null 2>&1 && [ -f "$BUILD_PS" ]; then
    echo 'sheen sync: running token build (materialize_tokens=true)...'
    pwsh -NonInteractive -File "$BUILD_PS" || { echo "sheen sync: token build failed" >&2; exit 1; }
  else
    echo 'sheen sync: materialize_tokens=true but pwsh/build-tokens.ps1 not found; skipping token build' >&2
  fi
fi
