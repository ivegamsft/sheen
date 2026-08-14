# GitHub Security Posture Report

**Date:** <!-- ISO 8601 date, e.g., 2026-05-01T00:00:00Z -->
**Organization:** <!-- e.g., my-org -->
**Repositories Audited:** <!-- e.g., my-org/api-service, my-org/frontend -->
**Audited By:** <!-- agent or engineer name -->
**Token Scopes Used:** `repo`, `read:org`

---

## Overall Posture Score

| Scope | Score | Pass | Warning | Fail |
|---|---|---|---|---|
| Organization | <!-- 🟢 / 🟡 / 🔴 --> | <!-- # --> | <!-- # --> | <!-- # --> |
| <!-- repo 1 --> | <!-- 🟢 / 🟡 / 🔴 --> | <!-- # --> | <!-- # --> | <!-- # --> |
| <!-- repo 2 --> | <!-- 🟢 / 🟡 / 🔴 --> | <!-- # --> | <!-- # --> | <!-- # --> |
| **Overall** | <!-- 🟢 / 🟡 / 🔴 --> | <!-- total --> | <!-- total --> | <!-- total --> |

---

## Org-Level Checks

### Organization: `{org}`

| # | Check | Rating | Finding |
|---|---|---|---|
| O1 | Code security configuration applied | <!-- 🟢 / 🟡 / 🔴 --> | <!-- e.g., "GitHub recommended" applied to all repos --> |
| O2 | Org rulesets defined | <!-- 🟢 / 🟡 / 🔴 --> | <!-- e.g., 2 active rulesets found --> |
| O3 | Secret scanning enabled at org level | <!-- 🟢 / 🟡 / 🔴 --> | <!-- e.g., enabled via code security config --> |
| O4 | Dependabot security updates enabled | <!-- 🟢 / 🟡 / 🔴 --> | <!-- e.g., enabled via code security config --> |

#### Org-Level Details

<!-- Add API response excerpts or notes for each check. Example:

O1 — Code security configuration:
- Configuration name: "GitHub recommended"
- Applied to: all repositories (enforced)
- API: GET /orgs/{org}/code-security/configurations

O2 — Org rulesets:
- Ruleset 1: "default-branch-protection" (active, targets: default branch)
- Ruleset 2: "require-signed-commits" (active)
-->

---

## Repo-Level Checks

<!-- Repeat this section for each repository audited -->

### Repository: `{owner}/{repo}`

**Default branch:** `<!-- main / master / etc. -->`

| # | Check | Rating | Finding |
|---|---|---|---|
| R1 | Branch protection on default branch | <!-- 🟢 / 🟡 / 🔴 --> | <!-- e.g., PR reviews required (1 approver), status checks enforced --> |
| R2 | Repo ruleset active | <!-- 🟢 / 🟡 / 🔴 --> | <!-- e.g., 1 active ruleset inherited from org --> |
| R3 | Secret scanning enabled | <!-- 🟢 / 🟡 / 🔴 --> | <!-- e.g., enabled --> |
| R4 | Push protection enabled | <!-- 🟢 / 🟡 / 🔴 --> | <!-- e.g., disabled → See #NNN --> |
| R5 | Code scanning configured | <!-- 🟢 / 🟡 / 🔴 --> | <!-- e.g., CodeQL configured; 0 open critical/high alerts --> |
| R6 | Dependabot alerts triaged | <!-- 🟢 / 🟡 / 🔴 --> | <!-- e.g., 2 open critical alerts → See #NNN, #NNN --> |
| R7 | Signed commits required | <!-- 🟢 / 🟡 / 🔴 --> | <!-- e.g., not required → See #NNN --> |
| R8 | CODEOWNERS file present | <!-- 🟢 / 🟡 / 🔴 --> | <!-- e.g., .github/CODEOWNERS found --> |

#### Repo-Level Details

<!-- Add context per failing or warning check. Example:

R4 — Push protection disabled:
- Current: secret_scanning_push_protection.status = disabled
- Risk: secrets may be pushed before detection
- Fix: gh api --method PATCH /repos/{owner}/{repo} --field security_and_analysis='{"secret_scanning_push_protection":{"status":"enabled"}}'
- Issue filed: #123

R6 — Open Dependabot alerts:
- lodash 4.17.15 — CVE-2021-23337 (Critical) — prototype pollution
- axios 0.21.1 — CVE-2021-3749 (High) — ReDoS
- Issue filed: #124
-->

---

## 🔴 Failing Checks — Remediation Actions

> Address all failing checks within 7 days. Critical Dependabot alerts within 24 hours.

<!-- One block per failing check -->

### [🔴 {Check Name}] — `{owner}/{repo}` or `{org}`

**Risk:** <!-- brief risk statement -->
**Linked Issue:** #<!-- issue number -->

```bash
# Remediation command
```

---

## 🟡 Warning Checks — Recommended Actions

> Address within 30 days.

<!-- One block per warning check -->

### [🟡 {Check Name}] — `{owner}/{repo}` or `{org}`

**Recommendation:** <!-- what to improve -->

```bash
# Optional remediation command
```

---

## Summary

### Findings by Severity

| Finding Type | Count | Issues Filed |
|---|---|---|
| 🔴 Fail — Critical | <!-- # --> | <!-- #NNN, #NNN --> |
| 🔴 Fail — High | <!-- # --> | <!-- #NNN, #NNN --> |
| 🔴 Fail — Medium | <!-- # --> | <!-- #NNN, #NNN --> |
| 🟡 Warning | <!-- # --> | <!-- optional --> |
| 🟢 Pass | <!-- # --> | — |

### Recommended Remediation Priority

1. <!-- Highest priority item — e.g., "Triage 2 critical Dependabot alerts in my-org/api-service (#124)" -->
2. <!-- Second priority — e.g., "Enable push protection on my-org/api-service (#123)" -->
3. <!-- Third priority -->

### Next Audit

Recommended re-audit: <!-- date, e.g., 30 days from now -->
