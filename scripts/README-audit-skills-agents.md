# Auditing skills and agents

`scripts/audit-skills-agents.ps1` is the unified structural auditor for
`skills/` and `agents/` (#131). It catches broken cross-references that no
single existing lint covers on its own, and wraps two pre-existing scripts
(`lint-router.ps1`, `audit-evals.ps1`) that previously were only referenced
in `publish-to-production.yml`'s internal-file strip-list and were never
actually executed as a gate.

## What it checks

| Category | Check |
|---|---|
| `skill-structure` | `SKILL.md` exists per skill folder; frontmatter `name` equals the folder name; `eval.yaml` present |
| `skill-description` | frontmatter `description` contains both a `USE FOR:` and a `DO NOT USE FOR:` clause |
| `agent-structure` | frontmatter `name` equals the file basename; `eval.yaml` present |
| `agent-description` | same `USE FOR:` / `DO NOT USE FOR:` check, for agents |
| `agent-composes` | every `composes.skills[]` entry resolves to a real `skills/<name>/` folder; every `composes.instructions[]` entry resolves to a real `instructions/<name>.instructions.md` |
| `catalog-drift` | **both directions**: every `skills/<name>/` reference in `skills/_catalog.md` exists on disk, *and* every skill folder on disk is referenced somewhere in the catalog (the second direction is new — without it, a shipped skill can go undiscoverable and nothing catches it) |
| `skill-delegates` | each skill's `## Delegates / pairs with` section references a real skill folder or agent name (backtick-quoted or single-token bullet lines only — freeform prose lines are skipped to avoid false positives) |
| `router-lint` | wraps `lint-router.ps1` (sheen.vocab.yaml intent/skill/agent/discriminator integrity) |
| `eval-quality` | wraps `audit-evals.ps1`'s specificity scoring; flags any eval file below the minimum score |

## How to run

```powershell
pwsh scripts/audit-skills-agents.ps1
pwsh scripts/audit-skills-agents.ps1 -OutFile dist/audit/skills-agents-findings.json -MinimumEvalScore 7.0
```

Exit code `0` when there are no error-severity findings (warnings never fail
the run on their own); `1` otherwise. The JSON report is written to
`dist/audit/skills-agents-findings.json` by default (git-ignored build
output — `dist/` is already ignored repo-wide).

## Filing issues from findings

`scripts/file-audit-issues.ps1` consumes that JSON report and files (or
auto-closes) GitHub issues via `gh`:

```powershell
pwsh scripts/file-audit-issues.ps1 -Repo owner/repo -DryRun   # preview only
pwsh scripts/file-audit-issues.ps1 -Repo owner/repo           # files/closes issues for real
```

Deduplication uses a stable per-finding fingerprint (`category|target|message`,
hashed) embedded as a hidden `<!-- audit-fingerprint: ... -->` marker in the
issue body, all under the `skills-agents-audit` label:

- A finding with no matching open issue → a new issue is created.
- A finding matching an already-open issue → left alone (no duplicate spam).
- An issue whose finding no longer appears in the latest report → auto-closed
  with an explanatory comment.

## CI integration

- **`ci.yml` → `skills-agents-audit` job** (every PR/push): validate-only.
  Runs the auditor and fails the build on any error-severity finding, then
  verifies the negative case (an intentionally-broken catalog reference must
  fail the audit) before restoring — mirroring the broken-fixture pattern
  used by `lint-diagram-geometry.ps1` (#118), `audit-diagram-slop.ps1`
  (#115), and the visual-regression suite (#129).
- **`.github/workflows/audit-skills-agents.yml`** (weekly cron +
  `workflow_dispatch`): runs the auditor and then `file-audit-issues.ps1`
  for real, so drift that accumulates between PRs still gets tracked as
  issues even when no PR is open to fail.

## Adding a new check

Add a new `Add-Finding -Severity <error|warning> -Category <name> -Target <path> -Message <text>`
call in `scripts/audit-skills-agents.ps1`. Use `error` only for something that
should block a PR; use `warning` for advisory findings that should still be
tracked as an issue but shouldn't fail CI on their own.
