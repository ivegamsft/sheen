---
name: design-audit
compatibility: [github-copilot-cli]
description: "Use when this skill is the right fit for the request. Top-level design assessment for an existing repo or product. USE FOR: repo-wide design audits, prioritizing UX/design debt, generating a remediation backlog from evidence. DO NOT USE FOR: editing only token files in isolation, greenfield system bootstrap from zero."
category: lifecycle
metadata:
  category: lifecycle
  maturity: stable
  audience: [designer, developer]
  pillar: lifecycle
allowed-tools: []
---
# Design Audit

Run a full-repo design governance audit and produce a prioritized backlog.

## Workflow
1. Inventory scope: surfaces, platforms, and user-critical journeys.
2. Run mapping passes (styles, typography, i18n, usability coverage) and collect gaps.
3. Evaluate against sheen standards: tokens, accessibility, usability, component coherence.
4. Severity-rank findings by user impact, risk, and implementation effort.
5. Convert findings into an actionable, ordered remediation backlog.

## Guardrails
- Do not rewrite product code as part of the audit pass.
- Do not claim compliance without concrete evidence per finding.
- Do not collapse separate issues into vague "polish" recommendations.

## Output
- Consolidated audit report with severity, rationale, and affected surfaces.
- Prioritized remediation backlog (quick wins, medium-term, structural fixes).

## Delegates / pairs with
- `css-mapping`, `font-mapping`, `i18n-framework-mapping`, `usability-mapping`
- `design-system-audit`, `accessibility-audit`, `web-usability-review`

