# Upgrading sheen in a Consumer Repository

This guide explains how to upgrade your sheen assets to a newer version after
the initial adoption. The upgrade process mirrors the original `sync.ps1` /
`sync.sh` workflow but adds pre-flight checks, a changelog preview, post-sync
validation, and an optional pull-request step.

---

## Quick reference

| Platform | Command |
|----------|---------|
| Windows (PowerShell) | `pwsh scripts/upgrade-sheen.ps1` |
| macOS / Linux (Bash) | `bash scripts/upgrade-sheen.sh` |
| Pin to a release | Add `--ref v0.7.0` |
| CI / no prompts | Add `--silent --skip-pr` |
| Dry-run preview | Add `--dry-run` |

---

## Before you begin

- You have already adopted sheen via `sync.ps1` or `sync.sh` and committed
  `.sheen.yml` and `.sheen/manifest.json`.
- Your working tree is clean (or you have staged/committed in-progress work).
- The GitHub CLI (`gh`) is installed if you want automatic PR creation.

---

## Step 1 — Check the changelog

Before upgrading, review what changed in the upstream sheen release you are
targeting. You can check it in several ways:

- **Automatically:** the upgrade scripts fetch and print the upstream
  `CHANGELOG.md` during Phase 3 of the upgrade run.
- **Manually:** visit the GitHub releases page or the
  [CHANGELOG.md](https://github.com/ivegamsft/sheen/blob/main/CHANGELOG.md)
  in the upstream source repo.

---

## Step 2 — Run the upgrade script

### Windows (PowerShell)

```powershell
# Upgrade to latest main (interactive)
pwsh scripts/upgrade-sheen.ps1

# Pin to a specific release
pwsh scripts/upgrade-sheen.ps1 -Ref v0.7.0

# CI mode — no prompts, no PR
pwsh scripts/upgrade-sheen.ps1 -Ref v0.7.0 -Silent -SkipPR

# Preview what would happen without making changes
pwsh scripts/upgrade-sheen.ps1 -Ref v0.7.0 -DryRun
```

### macOS / Linux (Bash)

```bash
# Upgrade to latest main (interactive)
bash scripts/upgrade-sheen.sh

# Pin to a specific release
bash scripts/upgrade-sheen.sh --ref v0.7.0

# CI mode — no prompts, no PR
bash scripts/upgrade-sheen.sh --ref v0.7.0 --silent --skip-pr

# Preview what would happen without making changes
bash scripts/upgrade-sheen.sh --ref v0.7.0 --dry-run
```

### Environment variables

Both scripts read these optional variables:

| Variable | Default | Description |
|----------|---------|-------------|
| `SHEEN_REPO` | value in `.sheen.yml` | Override upstream URL |
| `SHEEN_REF`  | value in `.sheen.yml` | Override branch or tag |

---

## What the upgrade script does

The script runs in six phases:

| Phase | What happens |
|-------|-------------|
| 1 Prerequisites | Verifies `git` is installed and you are inside a git repo |
| 2 Installed state | Reads `.sheen.yml` and `.sheen/manifest.json` to detect the currently installed version and source |
| 3 Changelog preview | Clones the upstream at the target ref and prints `CHANGELOG.md` (best-effort) |
| 4 Sync | Runs `sync.ps1` / `sync.sh` with the target ref, respecting your existing `.sheen.yml` allow-lists |
| 5 Validate | Runs `scripts/diagnose-sheen.ps1` / `diagnose-sheen.sh` to confirm the result |
| 6 PR | Optionally commits the changes to a branch and opens a GitHub pull request |

Your `.sheen.yml` is **not modified** by the upgrade script. It controls which
assets are synced, and the upgrade simply re-runs sync at the new ref.

---

## Pinning to a release tag (recommended for production)

For stable, reproducible upgrades pin `ref` in `.sheen.yml` to a semver tag:

```yaml
# .sheen.yml
source: https://github.com/ivegamsft/sheen.git
ref: v0.7.0   # ← pin to a release tag
```

Then run the upgrade script without `--ref`; it will use the tag in `.sheen.yml`.

To bump the pin, edit `.sheen.yml` and run the upgrade again.

---

## Upgrading in CI

Add a scheduled workflow or a manual dispatch that runs the upgrade script in
silent mode and opens a PR for team review:

```yaml
# .github/workflows/sheen-upgrade.yml
name: "Sheen — Scheduled Upgrade Check"

on:
  schedule:
    - cron: "0 9 * * 1"   # every Monday at 09:00 UTC
  workflow_dispatch:
    inputs:
      ref:
        description: "sheen ref to upgrade to (default: main)"
        default: main

permissions:
  contents: write
  pull-requests: write

jobs:
  upgrade:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Upgrade sheen assets
        env:
          GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
          SHEEN_REF: ${{ inputs.ref || 'main' }}
        run: bash scripts/upgrade-sheen.sh --silent
```

---

## Rolling back

If an upgrade introduces an issue, roll back to the previously synced state:

```powershell
# Windows
pwsh rollback.ps1
```

```bash
# macOS / Linux
bash rollback.sh
```

The rollback script reads `.sheen/manifest.json` and removes the files that were
written during the last sync, preserving any consumer-authored files that were
not part of the sync.

---

## Troubleshooting

### `sync.ps1` / `sync.sh` not found

The upgrade script relies on `sync.ps1` / `sync.sh` being present at the consumer
repo root. If it is missing, download the latest version from the
[sheen release assets](https://github.com/ivegamsft/sheen/releases/latest).

### Upgrade completed but expected assets are missing

Check your `.sheen.yml` allow-lists. If `skills: [design-review]` is set, only
that skill is synced. Remove or expand the allow-list to include additional assets.

### `diagnose-sheen` reports errors after upgrade

The diagnose script may surface breaking changes — for example, a renamed skill
or removed instruction file. Check the upstream `CHANGELOG.md` for migration
notes and update your `.sheen.yml` accordingly.

### Conflicts with consumer-owned files

The sync engine preserves consumer-owned files that were not written by a
previous sync. If you see a `preserving consumer-owned path` warning, review
those files manually and decide whether to keep or overwrite them.

For expanded troubleshooting, see the [sync troubleshooting guide](../quick-refs/sync-troubleshooting.md).
