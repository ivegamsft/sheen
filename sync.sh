#!/usr/bin/env bash
# sync.sh --- basecoat-sheen consumer sync (POSIX shell)

set -euo pipefail

DEFAULT_SOURCE="https://github.com/ivegamsft/sheen.git"
DEFAULT_REF="main"

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

source_dirs_for() {
  case "$1" in
    skills)       printf '%s\n' ".github/skills" "skills" ;;
    agents)       printf '%s\n' ".github/agents" "agents" ;;
    instructions) printf '%s\n' ".github/instructions" "instructions" ;;
    prompts)      printf '%s\n' ".github/prompts" "prompts" "vendor/basecoat/prompts" ;;
    templates)    printf '%s\n' "templates" ;;
    tokens)       printf '%s\n' "tokens" ;;
  esac
}

normalize_name() {
  local type="$1" raw="$2" value="$2"
  value="$(printf '%s' "$value" | sed -E 's/\.(md|markdown|txt|ya?ml|json)$//')"
  case "$type" in
    agents) value="$(printf '%s' "$value" | sed -E 's/\.agent(\.eval)?$//')" ;;
    instructions) value="$(printf '%s' "$value" | sed -E 's/\.instructions$//')" ;;
    prompts) value="$(printf '%s' "$value" | sed -E 's/\.prompt$//')" ;;
    themes) value="$(printf '%s' "$value" | sed -E 's/\.tokens$//')" ;;
  esac
  printf '%s' "$value"
}

command -v git >/dev/null 2>&1 || { echo "git is required" >&2; exit 1; }
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || { echo "Run this inside a git repository" >&2; exit 1; }
CONFIG="$REPO_ROOT/.sheen.yml"

yml_value() {
  [ -f "$CONFIG" ] || return 0
  sed -n "s/^$1:[[:space:]]*//p" "$CONFIG" | head -n1 \
    | sed 's/[[:space:]]*#.*$//' | sed 's/^"\(.*\)"$/\1/' | sed "s/^'\(.*\)'$/\1/" \
    | sed 's/[[:space:]]*$//'
}

# Prints "__ALL__" if absent; otherwise list entries (possibly empty).
yml_list() {
  local key="$1"
  [ -f "$CONFIG" ] || { echo "__ALL__"; return 0; }

  # top-level inline: key: [a,b]
  local inline
  inline="$(sed -n "s/^$key:[[:space:]]*\[\(.*\)\][[:space:]]*$/\1/p" "$CONFIG" | head -n1)"
  if grep -Eq "^$key:[[:space:]]*" "$CONFIG"; then
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
    return 0
  fi

  # nested under sync:
  awk -v key="$key" '
    BEGIN { in_sync=0; in_key=0 }
    /^[^[:space:]]/ {
      if ($0 ~ /^sync:[[:space:]]*$/) { in_sync=1; in_key=0; next }
      in_sync=0; in_key=0
    }
    in_sync==1 {
      if ($0 ~ "^[[:space:]]{2}"key":[[:space:]]*\\[(.*)\\][[:space:]]*$") {
        line=$0
        sub("^([[:space:]]{2}"key":[[:space:]]*\\[)","",line)
        sub("\\][[:space:]]*$","",line)
        n=split(line, arr, ",")
        for (i=1;i<=n;i++) {
          gsub(/^[[:space:]]+|[[:space:]]+$/, "", arr[i])
          if (arr[i] != "") print arr[i]
        }
        exit
      }
      if ($0 ~ "^[[:space:]]{2}"key":[[:space:]]*$") { in_key=1; next }
      if (in_key==1) {
        if ($0 ~ /^[[:space:]]{4}-[[:space:]]*/) {
          line=$0
          sub(/^[[:space:]]{4}-[[:space:]]*/, "", line)
          sub(/[[:space:]]*#.*$/, "", line)
          gsub(/^[[:space:]]+|[[:space:]]+$/, "", line)
          if (line != "") print line
          next
        }
        if ($0 ~ /^[[:space:]]*$/ || $0 ~ /^[[:space:]]*#/) next
        in_key=0
      }
    }
  ' "$CONFIG"
  if grep -Eq "^[[:space:]]{2}$key:" "$CONFIG" && grep -Eq "^sync:[[:space:]]*$" "$CONFIG"; then
    return 0
  fi
  echo "__ALL__"
}

is_excluded() {
  local rel="$1"; shift
  local p pat
  for p in "$@"; do
    [ -n "$p" ] || continue
    pat="$(printf '%s' "$p" | tr '\\' '/')"
    if [[ "$pat" == */ ]]; then
      pat="${pat%/}"
      [[ "$rel" == "$pat" || "$rel" == "$pat/"* ]] && return 0
      continue
    fi
    [[ "$rel" == $pat || "$rel" == "$pat/"* ]] && return 0
  done
  return 1
}

SOURCE="${SHEEN_REPO:-$(yml_value source)}"; [ -n "$SOURCE" ] || SOURCE="$DEFAULT_SOURCE"
REF="${SHEEN_REF:-$(yml_value ref)}"; [ -n "$REF" ] || REF="$DEFAULT_REF"
DISPLAY_SOURCE="$(echo "$SOURCE" | sed -E 's#^(https?://)[^/@]*@#\1#' | sed 's/[?#].*$//')"
echo "sheen sync: $DISPLAY_SOURCE @ $REF"

EXCLUDE_RAW="$(yml_list exclude || true)"
THEMES_RAW="$(yml_list themes || true)"
EXCLUDES=()
THEMES=()
[ "$EXCLUDE_RAW" != "__ALL__" ] && mapfile -t EXCLUDES <<< "$EXCLUDE_RAW"
[ "$THEMES_RAW" != "__ALL__" ] && mapfile -t THEMES <<< "$THEMES_RAW"

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
PREV_MANIFEST="$REPO_ROOT/.sheen/manifest.json"
PREV_FILES=""
if [ -f "$PREV_MANIFEST" ]; then
  PREV_FILES="$(awk '
    /"files"[[:space:]]*:/ { infiles=1; next }
    infiles && /\]/ { infiles=0 }
    infiles {
      line=$0; gsub(/[[:space:]]/,"",line); gsub(/,$/,"",line); gsub(/^"/,"",line); gsub(/"$/,"",line);
      if (line != "") print line
    }
  ' "$PREV_MANIFEST" || true)"
fi

is_managed_path() {
  local rel="$1"
  [ -z "$PREV_FILES" ] && return 1
  printf '%s\n' "$PREV_FILES" | grep -Fqx "$rel" && return 0
  printf '%s\n' "$PREV_FILES" | grep -E "^$(printf '%s' "$rel" | sed 's/[.[\*^$()+?{}|]/\\&/g')/" >/dev/null 2>&1 && return 0
  return 1
}

FILES_JSON=""
COUNT=0

for type in $TYPES; do
  SRC_DIRS=()
  while IFS= read -r rel; do
    [ -n "$rel" ] || continue
    cand="$WORK/$rel"
    [ -d "$cand" ] && SRC_DIRS+=("$cand")
  done < <(source_dirs_for "$type")
  [ ${#SRC_DIRS[@]} -gt 0 ] || continue

  ALLOW_RAW="$(yml_list "$type" || true)"
  ALLOW_SET=()
  if [ "$ALLOW_RAW" != "__ALL__" ]; then
    while IFS= read -r item; do
      [ -n "$item" ] || continue
      ALLOW_SET+=("$(normalize_name "$type" "$item")")
    done <<< "$ALLOW_RAW"
  fi

  DEST_ROOT="$REPO_ROOT/$(target_for "$type")"

  SEEN_BASES=()
  MATCHED_ALLOW=()
  for SRC_DIR in "${SRC_DIRS[@]}"; do
    for entry in "$SRC_DIR"/* "$SRC_DIR"/.[!.]*; do
      [ -e "$entry" ] || continue
      base="$(basename "$entry")"
      [ "$base" = ".gitkeep" ] && continue
      seen=0
      for b in "${SEEN_BASES[@]}"; do [ "$b" = "$base" ] && seen=1 && break; done
      [ $seen -eq 0 ] || continue
      SEEN_BASES+=("$base")
      src_rel="$type/$base"
      is_excluded "$src_rel" "${EXCLUDES[@]}" && continue

      norm="$(normalize_name "$type" "$base")"
      if [ "$ALLOW_RAW" != "__ALL__" ]; then
        match=0
        for a in "${ALLOW_SET[@]}"; do
          [ "$a" = "$norm" ] && match=1 && break
        done
        [ $match -eq 1 ] || continue
        already_matched=0
        for m in "${MATCHED_ALLOW[@]}"; do [ "$m" = "$norm" ] && already_matched=1 && break; done
        [ $already_matched -eq 0 ] && MATCHED_ALLOW+=("$norm")
      fi

      dest="$DEST_ROOT/$base"
      dest_rel="$(target_for "$type")/$base"
      if [ -e "$dest" ] && ! is_managed_path "$dest_rel"; then
        echo "sheen sync: preserving consumer-owned path (collision): $dest_rel" >&2
        continue
      fi

      mkdir -p "$DEST_ROOT"

      if [ -d "$entry" ]; then
        rm -rf "$dest"
        cp -R "$entry" "$dest"

        if [ "$type" = "tokens" ] && [ "$base" = "themes" ] && [ "$THEMES_RAW" != "__ALL__" ]; then
          for theme_entry in "$dest"/*; do
            [ -e "$theme_entry" ] || continue
            keep=0
            tbase="$(normalize_name themes "$(basename "$theme_entry")")"
            for t in "${THEMES[@]}"; do
              [ "$tbase" = "$(normalize_name themes "$t")" ] && keep=1 && break
            done
            [ $keep -eq 1 ] || rm -rf "$theme_entry"
          done
        fi

        while IFS= read -r file; do
          rel="${file#$REPO_ROOT/}"
          rel="${rel//\\//}"
          FILES_JSON="$FILES_JSON  \"$rel\",\n"
          COUNT=$((COUNT + 1))
        done < <(find "$dest" -type f | sort)
      else
        cp "$entry" "$dest"
        rel="${dest#$REPO_ROOT/}"
        rel="${rel//\\//}"
        FILES_JSON="$FILES_JSON  \"$rel\",\n"
        COUNT=$((COUNT + 1))
      fi
    done
  done

  # Warn about allow-list entries that matched nothing in source (#88)
  if [ "$ALLOW_RAW" != "__ALL__" ] && [ ${#ALLOW_SET[@]} -gt 0 ]; then
    for a in "${ALLOW_SET[@]}"; do
      already_matched=0
      for m in "${MATCHED_ALLOW[@]}"; do [ "$m" = "$a" ] && already_matched=1 && break; done
      if [ $already_matched -eq 0 ]; then
        echo "sheen sync: sync.$type allow-list entry '$a' did not match any source file; check spelling or suffix" >&2
      fi
    done
  fi
done

FILES_JSON="$(printf '%b' "$FILES_JSON" | sed '$ s/,$//')"
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

echo "sheen sync: wrote ${COUNT} file(s); manifest at .sheen/manifest.json"

MATERIALIZE="$(yml_value 'materialize_tokens')"
if [ "$MATERIALIZE" = 'true' ]; then
  BUILD_PS="$REPO_ROOT/scripts/build-tokens.ps1"
  if [ ! -f "$BUILD_PS" ]; then
    # Provision the build script from the upstream clone into the consumer repo (#86)
    UPSTREAM_BUILD_PS="$WORK/scripts/build-tokens.ps1"
    if [ -f "$UPSTREAM_BUILD_PS" ]; then
      mkdir -p "$REPO_ROOT/scripts"
      cp "$UPSTREAM_BUILD_PS" "$BUILD_PS"
      echo 'sheen sync: provisioned scripts/build-tokens.ps1 from upstream (materialize_tokens=true)'
    else
      echo 'sheen sync: materialize_tokens=true but build-tokens.ps1 not found in upstream; skipping token build' >&2
    fi
  fi
  if command -v pwsh >/dev/null 2>&1 && [ -f "$BUILD_PS" ]; then
    # Always pass consumer token paths explicitly (#92). build-tokens.ps1 also
    # auto-detects sheen/tokens, but sync must not rely on defaults alone.
    TOKENS_DIR="$REPO_ROOT/sheen/tokens"
    OUT_DIR="$REPO_ROOT/dist/tokens"
    echo "sheen sync: running token build (materialize_tokens=true; TokensDir=$TOKENS_DIR)..."
    pwsh -NonInteractive -File "$BUILD_PS" -TokensDir "$TOKENS_DIR" -OutDir "$OUT_DIR" \
      || { echo "sheen sync: token build failed" >&2; exit 1; }
  fi
fi

# ── generate_design_md: export DESIGN.md from DTCG tokens (Stitch/Google format) ──
GEN_DESIGN="$(yml_value 'generate_design_md')"
if [ "$GEN_DESIGN" = 'true' ]; then
  DESIGN_SH="$REPO_ROOT/scripts/build-design-md.sh"
  if [ ! -f "$DESIGN_SH" ]; then
    UPSTREAM_DESIGN_SH="$WORK/scripts/build-design-md.sh"
    if [ -f "$UPSTREAM_DESIGN_SH" ]; then
      mkdir -p "$REPO_ROOT/scripts"
      cp "$UPSTREAM_DESIGN_SH" "$DESIGN_SH"
      chmod +x "$DESIGN_SH"
      echo 'sheen sync: provisioned scripts/build-design-md.sh from upstream (generate_design_md=true)'
    else
      echo 'sheen sync: generate_design_md=true but build-design-md.sh not found in upstream; skipping' >&2
    fi
  fi
  if [ -f "$DESIGN_SH" ]; then
    DESIGN_THEME="$(yml_value 'design_md_theme')"
    DESIGN_THEME="${DESIGN_THEME:-light}"
    echo "sheen sync: generating DESIGN.md (generate_design_md=true; theme=${DESIGN_THEME})..."
    bash "$DESIGN_SH" --theme "$DESIGN_THEME" \
      || { echo "sheen sync: build-design-md failed" >&2; exit 1; }
  fi
fi
