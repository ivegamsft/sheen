# Diagnosing sheen syncs

`diagnose-sheen` checks a consumer repo after `sync.*` has finished. It validates
the consumer config, the synced asset layout, token JSON, cross-asset references,
and namespace collisions with vendored `basecoat`.

## When to run

Run it:

1. after every sync
2. before committing synced changes
3. in CI after your sync step

If the check fails, fix the reported issue and re-run before merging.

## How to run

```powershell
pwsh scripts/diagnose-sheen.ps1 -Json
pwsh scripts/diagnose-sheen.ps1 -Verbose
```

```bash
bash scripts/diagnose-sheen.sh --json
bash scripts/diagnose-sheen.sh --verbose
```

Use `-Json`/`--json` when you want a machine-readable report for CI or log
parsing. Use `-Verbose`/`--verbose` when you want extra diagnostic detail in the
human report.

## What the report means

The script emits four sections:

| Section | What it covers |
|---|---|
| `config` | `.sheen.yml` presence, YAML validity, required keys, allow-list membership |
| `structure` | synced directory layout, frontmatter, naming rules, eval coverage |
| `tokens` | JSON validity, alias resolution, theme completeness, semantic/core rules |
| `collisions` | duplicate names and reserved-prefix conflicts against vendored `basecoat` |

Severity is simple:

| Level | Meaning |
|---|---|
| `pass` | valid |
| `warn` | non-blocking advisory |
| `error` | blocking issue |

Exit codes:

| Code | Meaning |
|---|---|
| `0` | all clear, or warnings only |
| `1` | one or more blocking issues |
| `2` | the tool could not continue |

The PowerShell implementation is the reference runner. The shell entrypoint
keeps parity with the same checks for environments where `pwsh` is not
available.

## JSON output schema

The JSON report is shaped for CI consumption:

```json
{
  "timestamp": "2026-08-14T20:30:00Z",
  "config": { "valid": true, "ref": "main", "skills": 1 },
  "structure": { "valid": true, "messages": [] },
  "tokens": { "valid": true, "themes": ["light", "dark"] },
  "collisions": { "found": false, "details": [] },
  "summary": { "pass": 4, "warn": 0, "error": 0, "exit_code": 0 }
}
```

`summary.pass`, `summary.warn`, and `summary.error` count the section outcomes,
not the raw number of individual messages.

## Common errors and fixes

### `Token not found in core`

Your semantic token references a core token that does not exist. Check the token
name and make sure `sheen/tokens/core/*.tokens.json` exports it.

### `Namespace collision detected`

The synced sheen asset uses the same name as a vendored `basecoat` asset. Rename
the sheen asset or narrow the allow-list in `.sheen.yml`.

### `.sheen.yml invalid YAML`

Fix the file syntax first. The most common problems are a bad colon, the wrong
indentation, or mixing tabs and spaces.

### `Skill trigger phrases empty`

The skill frontmatter description is incomplete. Add a real description with both
`USE FOR:` and `DO NOT USE FOR:` phrases.

## CI integration

```yaml
- name: Validate sheen deployment
  run: pwsh scripts/diagnose-sheen.ps1 -Json > sheen-report.json
  continue-on-error: true

- name: Parse report
  run: jq -e '.summary.error == 0 and .config.valid and .tokens.valid' sheen-report.json
```

If you prefer to fail fast, drop `continue-on-error` and let the validation step
stop the job immediately.

## Practical guidance

- Keep your `.sheen.yml` allow-lists narrow until the repo has proven the sync.
- Treat warnings as cleanup work, not as merge blockers.
- Re-run the diagnostic after any token or asset rename.
- Check the JSON report into your CI logs when you need a history of sync health.
