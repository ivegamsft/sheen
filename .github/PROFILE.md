# CI/CD & Onboarding Profile

> **This is a shared enterprise EMU instance.** The `solo-dev` profile below
> governs only the **local authoring ceremony** (which workflow/template pack,
> local telemetry/secrets, no hooks). It does **not** govern merges — the
> **enterprise EMU org rulesets are authoritative** for everything landing on
> `main`. See [Enterprise EMU governance](#enterprise-emu-governance-authoritative).
> Do **not** use `--admin`/force bypass on this instance.

## Profile: `solo-dev`

basecoat-sheen uses the **solo-dev** workflow/template pack, mirroring basecoat's
profile model (`vendor/basecoat/scripts/bootstrap.ps1`). Machine-readable contract:
[`sheen-onboarding-profile.json`](sheen-onboarding-profile.json).

| Setting | Value | Effect |
|---|---|---|
| `branch_policy` | `minimal` | No *repo-level* protection added; enterprise rulesets govern `main` instead. |
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
- **No repo-level branch protection.** Honoring `branch_policy: minimal` — but on
  this shared instance the **enterprise EMU rulesets** (below) are what actually
  govern `main`, and they cannot be relaxed from this repo.

## Enterprise EMU governance (authoritative)

basecoat-sheen runs on a **shared enterprise EMU (Enterprise Managed Users)
instance**. Enterprise/org rulesets govern every change to `main` and **supersede**
the solo `branch_policy`. They are the intended controls — satisfy them via the
normal PR flow; **do not bypass**. In practice you must:

- **Open a PR** — direct pushes to `main` are rejected (`GH013`); no force-push,
  no branch deletion.
- **Pin every action to a full-length commit SHA** — `@v4` tags are rejected by the
  enterprise Actions policy. Approved pins used here: `actions/checkout@9c091bb…`,
  `actions/setup-python@5fda3b9…` (same pins basecoat uses).
- **Pass CodeQL code scanning** (high-or-higher / error threshold) and **code
  quality** (errors). Code Security + CodeQL default setup are enabled on the repo.
- **Copilot code review** runs on push.
- **Respect the agent-file path restriction** — `.github/agents/*.md` and
  `agents/*.md` are restricted by an enterprise ruleset (bypass: EnterpriseOwner).

**No admin bypass.** The code-scanning / code-quality / Copilot-review ruleset has
**no bypass actors**, so `--admin`/force merges do not apply. The org's PR rule
requires **0 human approvals**, so a maintainer may merge their own PR, but only
**after all enterprise checks pass**. See `branch_protection.enterprise_governance`
in the profile JSON.

## Repo security posture (matches basecoat)

GHAS repo-security features are enabled to **match `ivegamsft/basecoat`**.
These harden the shared enterprise instance and are **independent of the
`solo-dev` authoring ceremony — the profile stays `solo-dev`.**

| Feature | State |
|---|---|
| Code security (CodeQL) | ✅ enabled (default setup `configured`) |
| Dependabot security updates | ✅ enabled |
| Secret scanning | ✅ enabled |
| Secret scanning — push protection | ✅ enabled |
| Secret scanning — non-provider patterns | ✅ enabled |
| Secret scanning — validity checks | ✅ enabled |
| Secret scanning — AI detection | ✅ enabled |
| Secret scanning — delegated alert dismissal | ✅ enabled |
| Secret scanning — delegated bypass | ❌ disabled (matches basecoat) |

CodeQL default setup also satisfies the enterprise code-scanning ruleset on `main`.

## Upgrading to `team-dev`

The solo pack is only the local ceremony; enterprise governance already provides
team-grade gating. To formally move to `team-dev`, set `branch_policy: shared`, add
reviewer/PR-gate workflows and a `CODEOWNERS`, and move telemetry/secrets to
workflow scope.
