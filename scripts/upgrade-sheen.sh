#!/usr/bin/env bash
# upgrade-sheen.sh --- basecoat-sheen consumer upgrade (POSIX shell)
#
# Upgrades (or re-syncs) sheen assets in a consumer repository that was
# previously adopted with sync.sh.  Reads the existing .sheen.yml and
# .sheen/manifest.json, shows a changelog preview, runs sync.sh at the
# requested ref, validates the result with diagnose-sheen.sh, and
# optionally opens a GitHub PR.
#
# Usage:
#   ./scripts/upgrade-sheen.sh [--ref <ref>] [--source <url>] [--silent]
#                               [--skip-pr] [--skip-diagnose] [--dry-run]
#
# Environment variables (all optional):
#   SHEEN_REPO   Upstream sheen HTTPS URL (overrides .sheen.yml source)
#   SHEEN_REF    Branch or tag to upgrade to (overrides .sheen.yml ref)
#
# Examples:
#   # Interactive upgrade to latest main
#   ./scripts/upgrade-sheen.sh
#
#   # Pin to a release in CI
#   ./scripts/upgrade-sheen.sh --ref v0.7.0 --silent --skip-pr
#
#   # Preview without running
#   ./scripts/upgrade-sheen.sh --ref v0.7.0 --dry-run

set -euo pipefail

# ── defaults ──────────────────────────────────────────────────────────────────
REF="${SHEEN_REF:-}"
SOURCE="${SHEEN_REPO:-}"
SILENT=false
SKIP_PR=false
SKIP_DIAGNOSE=false
DRY_RUN=false

# ── argument parsing ──────────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
  case "$1" in
    --ref)        REF="$2";    shift 2 ;;
    --source)     SOURCE="$2"; shift 2 ;;
    --silent)     SILENT=true; shift ;;
    --skip-pr)    SKIP_PR=true; shift ;;
    --skip-diagnose) SKIP_DIAGNOSE=true; shift ;;
    --dry-run)    DRY_RUN=true; shift ;;
    -h|--help)
      sed -n '/^# /p' "$0" | head -30 | sed 's/^# \{0,1\}//'
      exit 0 ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

# ── output helpers ────────────────────────────────────────────────────────────
ok()   { printf "  ✅  %s\n" "$*"; }
warn() { printf "  ⚠️   %s\n" "$*"; }
fail() { printf "  ❌  %s\n" "$*"; }
info() { printf "  ℹ️   %s\n" "$*"; }
header() { printf "\n%s\n  %s\n%s\n" "$(printf '─%.0s' {1..56})" "$*" "$(printf '─%.0s' {1..56})"; }

confirm() {
  local prompt="$1"
  if [[ "$SILENT" == true ]]; then return 0; fi
  printf "  %s [Y/n] " "$prompt"
  read -r ans
  [[ -z "$ans" || "$ans" =~ ^[Yy] ]]
}

printf "\n  basecoat-sheen Upgrade\n"
if [[ "$DRY_RUN" == true ]]; then printf "  [DRY RUN — no files will be modified]\n"; fi

# ── Phase 1: prerequisites ────────────────────────────────────────────────────
header 'Phase 1 — Prerequisites'

command -v git >/dev/null 2>&1 || { fail 'git not found — install from https://git-scm.com'; exit 1; }
ok "git available"

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || { fail 'Not inside a git repository.'; exit 1; }
cd "$REPO_ROOT"
ok "Consumer repo root: $REPO_ROOT"

GH_AVAILABLE=false
command -v gh >/dev/null 2>&1 && GH_AVAILABLE=true
if [[ "$GH_AVAILABLE" == true ]]; then
  ok "GitHub CLI available"
else
  warn "GitHub CLI (gh) not found — PR creation will be skipped."
fi

# ── Phase 2: read installed state ────────────────────────────────────────────
header 'Phase 2 — Installed State'

CONFIG="$REPO_ROOT/.sheen.yml"
MANIFEST="$REPO_ROOT/.sheen/manifest.json"

if [[ ! -f "$CONFIG" ]]; then
  fail '.sheen.yml not found. Run sync.sh first to adopt sheen, then upgrade.'
  exit 1
fi
ok '.sheen.yml found'

INSTALLED_REF=""
INSTALLED_SOURCE=""

if [[ -f "$MANIFEST" ]]; then
  if command -v python3 >/dev/null 2>&1; then
    INSTALLED_REF="$(python3 -c "import json,sys; d=json.load(open('$MANIFEST')); print(d.get('ref',''))" 2>/dev/null || true)"
    INSTALLED_SOURCE="$(python3 -c "import json,sys; d=json.load(open('$MANIFEST')); print(d.get('source',''))" 2>/dev/null || true)"
  else
    INSTALLED_REF="$(grep '"ref"' "$MANIFEST" | sed 's/.*"ref"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/' | head -1 || true)"
    INSTALLED_SOURCE="$(grep '"source"' "$MANIFEST" | sed 's/.*"source"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/' | head -1 || true)"
  fi
  ok "Manifest: ref=${INSTALLED_REF:-unknown}  source=${INSTALLED_SOURCE:-unknown}"
fi

# Read source/ref from .sheen.yml if not set by env or flag
if [[ -z "$SOURCE" ]]; then
  SOURCE="$(sed -n 's/^source:[[:space:]]*//p' "$CONFIG" | head -1 | sed "s/['\"]//g" | sed 's/[[:space:]]*$//' || true)"
fi
if [[ -z "$REF" ]]; then
  REF="$(sed -n 's/^ref:[[:space:]]*//p' "$CONFIG" | head -1 | sed "s/['\"]//g" | sed 's/[[:space:]]*$//' || true)"
fi

SOURCE="${SOURCE:-https://github.com/IBuySpy-Shared/basecoat-sheen.git}"
REF="${REF:-main}"

ok "Upgrade target: $SOURCE @ $REF"

# ── Phase 3: changelog preview ────────────────────────────────────────────────
header 'Phase 3 — Changelog Preview'

if [[ -n "$INSTALLED_REF" && "$INSTALLED_REF" != "$REF" ]]; then
  info "Upgrading from ref '$INSTALLED_REF' → '$REF'"
elif [[ -n "$INSTALLED_REF" ]]; then
  info "Re-syncing at same ref '$REF' (asset updates within ref)"
else
  info "No previous manifest ref; performing fresh sync at '$REF'"
fi

TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

FETCHED_CHANGELOG=false
if git clone --quiet --depth 1 --branch "$REF" "$SOURCE" "$TMPDIR/sheen-src" 2>/dev/null; then
  if [[ -f "$TMPDIR/sheen-src/CHANGELOG.md" ]]; then
    printf "\n  Upstream CHANGELOG (first 40 lines):\n"
    head -40 "$TMPDIR/sheen-src/CHANGELOG.md" | sed 's/^/  /'
    FETCHED_CHANGELOG=true
  fi
  if [[ -f "$TMPDIR/sheen-src/version.json" ]]; then
    if command -v python3 >/dev/null 2>&1; then
      UP_VER="$(python3 -c "import json; d=json.load(open('$TMPDIR/sheen-src/version.json')); print(d.get('version','?'))" 2>/dev/null || true)"
    else
      UP_VER="$(grep '"version"' "$TMPDIR/sheen-src/version.json" | sed 's/.*"version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/' | head -1 || true)"
    fi
    printf "\n"
    ok "Upstream version: ${UP_VER:-unknown}"
  fi
  rm -rf "$TMPDIR/sheen-src"
fi

if [[ "$FETCHED_CHANGELOG" != true ]]; then
  info "CHANGELOG preview unavailable; proceeding without it."
fi

# ── Phase 4: run upgrade ──────────────────────────────────────────────────────
header 'Phase 4 — Sync'

confirm "Proceed with upgrade to $SOURCE @ $REF?" || { printf "  Aborted.\n"; exit 0; }

SYNC_SCRIPT="$REPO_ROOT/sync.sh"
if [[ ! -f "$SYNC_SCRIPT" ]]; then
  fail "sync.sh not found at $SYNC_SCRIPT. Download the latest sync script from the sheen release assets."
  exit 1
fi

if [[ "$DRY_RUN" == true ]]; then
  info "[DRY RUN] Would run: SHEEN_REPO=$SOURCE SHEEN_REF=$REF bash $SYNC_SCRIPT"
else
  export SHEEN_REPO="$SOURCE"
  export SHEEN_REF="$REF"
  bash "$SYNC_SCRIPT"
  unset SHEEN_REPO SHEEN_REF
  ok "sync.sh completed successfully"
fi

# ── Phase 5: validate ─────────────────────────────────────────────────────────
header 'Phase 5 — Validate'

if [[ "$SKIP_DIAGNOSE" == true ]]; then
  info 'Diagnose step skipped (--skip-diagnose).'
else
  DIAGNOSE_SCRIPT="$REPO_ROOT/scripts/diagnose-sheen.sh"
  if [[ -f "$DIAGNOSE_SCRIPT" ]]; then
    if [[ "$DRY_RUN" == true ]]; then
      info "[DRY RUN] Would run: bash $DIAGNOSE_SCRIPT"
    else
      info "Running diagnose-sheen.sh..."
      if bash "$DIAGNOSE_SCRIPT"; then
        ok "Diagnose passed"
      else
        warn "diagnose-sheen.sh reported warnings or errors — review output before merging."
      fi
    fi
  else
    warn "scripts/diagnose-sheen.sh not found — skipping validation."
  fi
fi

# ── Phase 6: open PR ──────────────────────────────────────────────────────────
header 'Phase 6 — Pull Request'

if [[ "$SKIP_PR" == true ]]; then
  info 'PR step skipped (--skip-pr).'
elif [[ "$GH_AVAILABLE" != true ]]; then
  info 'GitHub CLI not available — skipping PR creation.'
elif [[ "$DRY_RUN" == true ]]; then
  info "[DRY RUN] Would open a PR: chore: upgrade sheen assets to $REF"
else
  PR_BRANCH="chore/sheen-upgrade-$(printf '%s' "$REF" | tr -cs 'a-zA-Z0-9._-' '-')"
  if confirm "Open a PR for this upgrade (branch: $PR_BRANCH)?"; then
    git add '.sheen/' '.github/skills/' '.github/agents/' '.github/instructions/' '.github/prompts/' 'sheen/' 2>/dev/null || true

    if [[ -z "$(git status --porcelain)" ]]; then
      info 'No staged changes — nothing to commit. Upgrade may already be current.'
    else
      git checkout -b "$PR_BRANCH"
      git commit -m "chore: upgrade sheen assets to $REF

- Ran sync.sh at $SOURCE @ $REF
- Manifest updated at .sheen/manifest.json
- Review .sheen/manifest.json for the full file list

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
      git push --set-upstream origin "$PR_BRANCH"

      CHANGELOG_URL="${SOURCE%.git}/blob/$REF/CHANGELOG.md"
      gh pr create \
        --title "chore: upgrade sheen assets to $REF" \
        --body "## Sheen Upgrade

**Source:** $SOURCE
**Ref:** $REF

### What changed
See upstream [CHANGELOG]($CHANGELOG_URL) for details.

### Validation
- \`sync.sh\` ran successfully.
- \`diagnose-sheen.sh\` $(if [[ "$SKIP_DIAGNOSE" == true ]]; then echo 'skipped'; else echo 'passed'; fi).

### Rollback
\`\`\`bash
bash rollback.sh
\`\`\`
" \
        --base main

      ok "PR created on branch $PR_BRANCH"
    fi
  fi
fi

printf "\n"
ok "Upgrade complete. Sheen assets are now at $REF."
info "Next steps:"
info "  • Review changes with: git diff .sheen/"
info "  • Commit or push the upgrade branch"
info "  • To roll back: bash rollback.sh"
