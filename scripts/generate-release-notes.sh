#!/usr/bin/env bash
#
# Generate release notes for a tag/version by extracting the matching section
# from CHANGELOG.md, falling back to the [Unreleased] section, then to git log.
#
# Ported from basecoat's scripts/generate-release-notes.sh and adapted to sheen's
# Keep a Changelog heading style: "## [X.Y.Z] — YYYY-MM-DD" and "## [Unreleased]".
#
# Usage: generate-release-notes.sh <tag> <version> [notes-file]

set -euo pipefail

if [[ $# -lt 2 ]]; then
  echo "Usage: $0 <tag> <version> [notes-file]" >&2
  exit 1
fi

tag="$1"
version="$2"
notes_file="${3:-release-notes.md}"
changelog_file="${RELEASE_NOTES_CHANGELOG_FILE:-CHANGELOG.md}"

# Extract the body of a "## <heading>" section, where heading normalizes to the
# target (brackets stripped, "v" prefix optional). Prints heading + body.
extract_section() {
  local target="$1" section_file="$2"
  awk -v target="${target}" '
    function norm(s) {
      sub(/^##[[:space:]]+/, "", s)
      # keep only the label before a date separator (hyphen or em dash)
      sub(/[[:space:]]+[-—].*$/, "", s)
      gsub(/\[/, "", s); gsub(/\]/, "", s)
      gsub(/^v/, "", s)
      sub(/^[ \t]+/, "", s); sub(/[ \t]+$/, "", s)
      return s
    }
    BEGIN { capture = 0; found = 0 }
    /^##[[:space:]]+/ {
      if (capture == 1) { exit 0 }
      if (norm($0) == target) { capture = 1; found = 1; print; next }
    }
    { if (capture == 1) print }
    END { if (found == 0) exit 2 }
  ' "${changelog_file}" > "${section_file}"
}

# True if the section file has non-blank content beyond its heading line.
has_body() {
  awk 'NR==1{next} /^[[:space:]]*$/{next} {found=1; exit 0} END{exit found?0:1}' "$1"
}

fallback_git_history() {
  local previous_tag range from_label
  previous_tag="$(git tag --list 'v*.*.*' --sort=-v:refname | grep -Fxv "${tag}" | head -n1 || true)"
  range="${GITHUB_SHA:-HEAD}"
  from_label="the initial commit"
  if [[ -n "${previous_tag}" ]]; then
    range="${previous_tag}..${GITHUB_SHA:-HEAD}"
    from_label="${previous_tag}"
  fi
  {
    printf '## %s\n\n' "${version}"
    printf '_Auto-generated from commit history since %s._\n\n' "${from_label}"
    printf '### Changes\n\n'
    git log --no-merges --pretty='- %s (%h)' "${range}" || true
  } > "${notes_file}"
  grep -q '^- ' "${notes_file}" || printf -- '- No commits found in selected range.\n' >> "${notes_file}"
}

if [[ -f "${changelog_file}" ]] && extract_section "${version}" release-section.md && has_body release-section.md; then
  cp release-section.md "${notes_file}"
elif [[ -f "${changelog_file}" ]] && extract_section "Unreleased" release-section.md && has_body release-section.md; then
  {
    printf '## %s\n\n' "${version}"
    printf '_Derived from the `## [Unreleased]` section of CHANGELOG.md._\n\n'
    tail -n +2 release-section.md
  } > "${notes_file}"
else
  fallback_git_history
fi

rm -f release-section.md
echo "Wrote release notes to ${notes_file}"
