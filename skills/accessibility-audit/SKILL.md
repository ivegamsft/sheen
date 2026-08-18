---
name: accessibility-audit
compatibility: [github-copilot-cli]
description: "WCAG 2.2 AA accessibility conformance audit for UI surfaces. USE FOR: a11y issue discovery and triage, remediation planning, conformance statement drafting. DO NOT USE FOR: only checking color-pair contrast, non-accessibility style preference reviews."
category: a11y
metadata:
  category: a11y
  maturity: stable
  audience: [designer, developer]
  pillar: a11y
allowed-tools: []
---
# Accessibility Audit

Audit UI artifacts against WCAG 2.2 AA and ARIA/APG interaction guidance.

## Workflow
1. Scope target pages, components, and user journeys.
2. Evaluate by WCAG principles and key success criteria with evidence.
3. Verify ARIA role/state usage and keyboard interaction model.
4. Severity-rate issues and map each to concrete remediation guidance.
5. Summarize residual risks and conformance posture.

## Guardrails
- Do not label issues "passed" without criterion-level evidence.
- Do not collapse distinct failures into one generic recommendation.
- Do not substitute heuristic UX feedback for accessibility conformance checks.

## Output
- Accessibility audit report with criterion mapping, severity, and remediation plan.
- Conformance summary suitable for stakeholder and engineering handoff.

## Delegates / pairs with
- `color-contrast-check`, `web-usability-review`, `component-spec`
- agent: `accessibility-auditor`

