---
name: visual-regression
compatibility: [github-copilot-cli]
description: "Use when setting up visual snapshot baselines, triaging visual diffs, or detecting design QA drift. USE FOR: snapshot baseline setup, visual diff triage, design QA drift detection. DO NOT USE FOR: functional test authoring, security threat modeling."
category: governance
metadata:
  category: governance
  maturity: beta
  audience: [designer, developer]
  pillar: governance
allowed-tools: []
---

# visual-regression

Detect and triage unintended visual changes.

## Workflow
1. Define governed scope, policy expectations, and acceptance criteria.
2. Evaluate artifacts against explicit contracts and standards.
3. Record non-conformance findings with severity and remediation path.
4. Recommend policy-safe improvements with escalation thresholds.
5. Publish a concise decision log for review and auditability.

## Guardrails
- Do not approve out-of-policy changes without documented exception path.
- Do not hide uncertainty in compliance judgments.
- Do not recommend changes without clear ownership and closure criteria.
- Do not conflate style preference with contractual requirement.

## Output
- Governance report with findings, severity, and remediation owners.
- Decision log with follow-up checkpoints.

## Delegates / pairs with
- design-update
- design-system-audit
