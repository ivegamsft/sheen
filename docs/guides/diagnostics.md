# Sync diagnostics

`diagnose-sheen` validates a repo after a sheen sync. It checks the sync config,
asset layout, design-token resolution, and collisions between local sheen assets
and vendored `basecoat` assets.

## Run the diagnostic

From the target repository root:

```powershell
pwsh scripts\diagnose-sheen.ps1
pwsh scripts\diagnose-sheen.ps1 -Json > sheen-report.json
```

On Unix-like runners:

```bash
bash scripts/diagnose-sheen.sh
bash scripts/diagnose-sheen.sh --json > sheen-report.json
```

Exit codes are:

| Code | Meaning |
|---|---|
| `0` | All sections passed, or warnings only |
| `1` | One or more blocking validation errors |
| `2` | The diagnostic could not run |

## Human-readable report

The default report prints four sections:

| Section | Checks |
|---|---|
| `config` | `.sheen.yml` syntax, required keys, and allow-list entries |
| `structure` | synced directories, frontmatter, naming, eval files, and references (consumer runs scope to `.sheen/manifest.json` or allow-lists so unrelated BaseCoat assets are ignored) |
| `tokens` | token JSON validity, semantic/core references, theme completeness, and cycles |
| `collisions` | duplicate Sheen-managed asset names and reserved `basecoat-*` prefixes |

Messages are reported as `pass`, `warn`, or `error`. Errors produce exit code
`1`.

## JSON manifest schema

`-Json`/`--json` emits a machine-readable manifest:

```json
{
  "timestamp": "2026-08-16T09:49:00Z",
  "config": {
    "valid": true,
    "source": "https://github.com/IBuySpy-Shared/basecoat-sheen.git",
    "ref": "main",
    "skills": 3,
    "agents": 1,
    "instructions": 1,
    "themes": 3,
    "messages": []
  },
  "structure": { "valid": true, "messages": [] },
  "tokens": {
    "valid": true,
    "themes": ["light", "dark", "high-contrast"],
    "resolution": { "core": 120, "semantic": 40, "themes": 120 },
    "messages": []
  },
  "collisions": { "found": false, "details": [], "messages": [] },
  "summary": { "pass": 4, "warn": 0, "error": 0, "exit_code": 0 }
}
```

Use `summary.error == 0` as the primary CI gate, and inspect each section's
`messages` array for remediation details.
