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
| `skill-delegates` | explicit leading references in `## Delegates / pairs with` resolve locally first, then against verified external declarations; unregistered/unverified names remain warnings |
| `external-registry` | missing, malformed, duplicate/ambiguous or unsafe registry declarations are errors; no declarations accepted from invalid configuration |
| `external-target` | declared target unavailable, mismatched frontmatter identity or unsafe link remains an advisory warning, never verified |
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

## Explicit source dependencies

`scripts/external-delegates.json` is a **source-audit** allowlist, not an
installation manifest or authority grant. Schema version 1 has exactly
`schema_version` (integer 1) and `dependencies` (array). Every declaration has
exactly string `provider`, `kind`, `name`, `path`; provider/name are lower-case
kebab identifiers and kind is `skill` or `agent`. Names must be unique across
providers and kinds because delegate references are unqualified. Duplicate JSON
keys and additional fields are invalid. An explicit empty array is valid and
resolves no external names; an absent registry is an error.

Allowed installed roots and exact path shapes are `.github/skills/<name>/SKILL.md`
and `.github/agents/<name>.agent.md`. Paths use canonical `/` separators in JSON.
Traversal, absolute/network paths, other roots/files and reparse points/symlinks
on the target path are rejected. Kind follows the path convention; the one
`name` in bounded YAML frontmatter must exactly match the declaration (quoted
scalars are accepted). Only declared headers are read (maximum 128 lines or
32,768 UTF-16 code units, including a limit on unterminated lines); no installed
or vendor inventory is scanned. Diagnostics never echo file content. Expected
configuration/IO failures become diagnostics; unexpected implementation errors
propagate rather than being mislabeled as unavailable dependencies.

Root Sheen skill/agent names take precedence. The shared `Get-AssetDelegates`
parser still recognizes only supported explicit references/Feeds in Delegates;
evals, body prose, and transitive relationships do not establish ownership.
The report lists each verified external handoff separately in
`external_resolutions` with source, provider, kind, name, path; deterministic
findings/resolutions do not include file contents. The existing report envelope
retains its generation timestamp.

Availability in this checkout does **not** guarantee installation, permissions,
or specialist authority in a downstream consumer. Resolve external tools there
at execution time. This changes neither W04 nor downstream policy.

`test-external-delegates.ps1` exercises the shared resolver with source-shaped
positive/negative fixtures under ignored `dist/`, including true unknowns and
link escapes, and checks actual source handoffs. This auditor, registry, helper,
tests and this README are source-only and stripped by the publisher: shipping
the auditor without its already-stripped routing library would leave an orphan.
Post-sanitation metadata regeneration remains unchanged.

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
