---
name: craft-quality
compatibility: [github-copilot-cli]
description: "Use when running a craft and polish pass to assess consistency, refinement, typography, spacing, and visual fit-and-finish. USE FOR: craft checklist passes, polish quality assessments, consistency refinements. DO NOT USE FOR: governed design approval reports, formal usability audits, framework detection scans."
category: governance
metadata:
  category: governance
  maturity: stable
  audience: [designer, developer]
  pillar: governance
allowed-tools: []
---

# craft-quality

Apply craft-quality standards with actionable findings.

## Workflow

1. Define governed scope, policy expectations, and acceptance criteria.
2. Read and apply the [typography and structural review](references/typography-structure.md); evaluate artifacts against explicit contracts and standards.
3. Record non-conformance findings with severity and remediation path.
4. Recommend policy-safe improvements with escalation thresholds.
5. Publish a concise decision log for review and auditability.

## Guardrails

- Do not approve out-of-policy changes without documented exception path.
- Do not hide uncertainty in compliance judgments.
- Do not recommend changes without clear ownership and closure criteria.
- Do not conflate style preference with contractual requirement.
- Do not mandate a specific typeface, measurement, or visual treatment when
  reviewing typography or structural devices.
- Do not replace `design-review` when the requested output is a policy-governed
  approval report with severity, owners, and closure criteria.

## Output

- Governance report with findings, severity, and remediation owners.
- Decision log with follow-up checkpoints.
- Separate system-contract violations from subjective craft recommendations.

## Delegates / pairs with

- design-review
- design-debate
