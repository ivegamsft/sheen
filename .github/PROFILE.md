# CI/CD & Onboarding Profile

## Profile: `solo-dev`

basecoat-sheen is onboarded with the **solo-dev** profile, mirroring basecoat's
profile model (`vendor/basecoat/scripts/bootstrap.ps1`). Machine-readable contract:
[`sheen-onboarding-profile.json`](sheen-onboarding-profile.json).

| Setting | Value | Effect |
|---|---|---|
| `branch_policy` | `minimal` | No protected branches / required reviews; self-merge allowed. CI is the gate. |
| `workflow_pack` | `solo` | Only `ci.yml` + `docs.yml` (see below). |
| `template_pack` | `solo` | Lightweight issue/PR templates (added when needed). |
| `telemetry_mode` | `local` | No adoption/metrics workflows or org telemetry. |
| `secrets_mode` | `local` | No repo/org secrets required. |
| `hook_pack` | `none` | No git hooks installed. |

## CI/CD audit — basecoat vs. sheen (solo pack)

basecoat ships **~95 workflows** across the team/regulated packs (portal deploy,
release trains, governance/branch-protection enforcement, memory sweeps, adoption
metrics, reviewer auto-assign, cross-repo sync, secret-scan gates, MCP build/deploy,
etc.). Almost all assume an org, protected branches, reviewers, and org secrets —
out of scope for a solo repo.

The **solo pack** keeps only what a single developer needs:

| Workflow | Purpose | Basecoat analogue |
|---|---|---|
| `ci.yml` → `lint-and-validate` | Skill/agent/instruction frontmatter + naming + catalog-drift lint | `ci.yml`, `validate-basecoat.yml`, `skill-audit.yml` |
| `ci.yml` → `tokens` | DTCG token JSON validity (contrast/reference gates land with `scripts/validate-tokens`) | `token-preflight.yml`, `token-inventory.yml` |
| `docs.yml` | Build mkdocs site (strict) when configured | `docs.yml` |

### Deliberately excluded (activate on upgrade to team-dev)

Branch-protection enforcement, reviewer auto-assign / PR auto-merge, release train &
changelog automation, portal/extension deploy, memory sweep & adoption metrics,
cross-repo sync, org secret-scan gates.

## Design notes

- **Never scans `vendor/`.** All lint/validation targets root assets only; the
  vendored basecoat tree is read-only and validated upstream.
- **No-ops before assets exist.** Every step skips gracefully while `skills/`,
  `agents/`, `instructions/`, and `tokens/` are still empty (pre-implementation),
  so CI is green today and tightens automatically as assets land.
- **No branch protection.** Honoring `branch_policy: minimal`. To harden, flip
  `branch_protection.enabled` in the profile JSON and add the team-pack workflows.

## Org ruleset override (important)

The **IBuySpy-Shared org** enforces branch rulesets on `main` that **supersede**
the repo-level solo policy. In practice you must:

- **Open a PR** — direct pushes to `main` are rejected (`GH013`).
- **Pin every action to a full-length commit SHA** — `@v4` tags are rejected.
  The org-approved pins used here: `actions/checkout@9c091bb…`,
  `actions/setup-python@5fda3b9…` (same pins basecoat uses).
- **Wait for Code Scanning** — merges gate on code-scanning results.

So even under solo-dev, the effective flow is PR-based. `self_merge_allowed`
remains true (no reviewer required), but the org status gates still apply. See
`branch_protection.org_ruleset_override` in the profile JSON.

## Upgrading to `team-dev`

Set `branch_policy: shared`, enable branch protection with
`required_status_checks: ["Sheen - CI / lint-and-validate"]`, add reviewer/PR-gate
workflows, and move telemetry/secrets to workflow scope.
