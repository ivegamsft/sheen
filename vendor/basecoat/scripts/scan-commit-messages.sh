#!/usr/bin/env bash

set -euo pipefail

RANGE="${1:-HEAD~20..HEAD}"

if ! command -v git >/dev/null 2>&1; then
  echo "git is required" >&2
  exit 1
fi

if ! git rev-parse --git-dir >/dev/null 2>&1; then
  echo "Run this inside a git repository" >&2
  exit 1
fi

patterns=(
  "Private key marker:::-----BEGIN (RSA|EC|OPENSSH|DSA|PRIVATE) KEY-----"
  "GitHub token:::gh[pousr]_[A-Za-z0-9]{20,}"
  "AWS access key:::AKIA[0-9A-Z]{16}"
  "Azure connection string:::DefaultEndpointsProtocol=.*AccountKey="
  "Generic secret assignment:::(api[_-]?key|secret|client[_-]?secret|password|token)[[:space:]]*[:=][[:space:]]*[^[:space:]]+"
  "Potential SSN:::[0-9]{3}-[0-9]{2}-[0-9]{4}"
  "Potential credit card:::[0-9]{4}[- ][0-9]{4}[- ][0-9]{4}[- ][0-9]{4}"
)

failed=0

while IFS= read -r commit; do
  [[ -z "$commit" ]] && continue
  message="$(git log -n 1 --format=%B "$commit")"

  for entry in "${patterns[@]}"; do
    label="${entry%%:::*}"
    regex="${entry#*:::}"
    if grep -Eiq -- "$regex" <<<"$message"; then
      echo "[SECURITY] $label detected in commit message for $commit" >&2
      echo "$message" >&2
      failed=1
    fi
  done
done < <(git rev-list "$RANGE")

if [[ $failed -ne 0 ]]; then
  echo "Commit message scan failed. Remove sensitive content and rewrite commit message history." >&2
  exit 1
fi

echo "Commit message scan passed"