---
name: color-contrast-check
compatibility: [github-copilot-cli]
description: "Use when validating color pair contrast ratios for accessibility compliance or theme readiness. USE FOR: contrast ratio checks, theme pair validation, wcag contrast triage. DO NOT USE FOR: full accessibility audits, navigation IA design."
category: a11y
metadata:
  category: a11y
  maturity: stable
  audience: [designer, developer]
  pillar: a11y
allowed-tools: []
---

# color-contrast-check

Check semantic/theme color contrast against WCAG thresholds.

## Workflow
1. Scope evaluated journeys and applicable accessibility criteria.
2. Identify barriers in semantics, interaction, contrast, and content behavior.
3. Define remediations with implementation intent and user impact.
4. Verify keyboard/screen-reader and contrast behavior expectations.
5. Produce conformance-oriented issues with severity and ownership.

## Guardrails
- Do not claim compliance without criterion-level evidence.
- Do not accept color-only or pointer-only interaction dependencies.
- Do not downgrade critical barriers as cosmetic issues.
- Do not ignore regressions introduced by theme or component overrides.

## Output
- Accessibility issue register mapped to criteria and severity.
- Remediation guidance with verification notes.

## Delegates / pairs with
- theming
- color-system
