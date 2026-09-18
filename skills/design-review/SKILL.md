---
name: design-review
compatibility: [github-copilot-cli]
description: "Use when reviewing a specific design artifact or flow against principles, policy, and system guidelines with severity-ranked findings. USE FOR: artifact governance critique, principle-based review, remediation-owner findings. DO NOT USE FOR: standalone craft polish passes, multi-option debate facilitation, full repo audits."
category: governance
metadata:
  category: governance
  maturity: stable
  audience: [designer, developer]
  pillar: governance
allowed-tools: []
---

# design-review

Run governance reviews for a single design artifact or flow.

## Workflow

1. Define governed scope, policy expectations, and acceptance criteria.
2. Evaluate artifacts against explicit principles, policy, and system standards. Read and apply the [real-content critique loop](references/real-content-critique.md), including state extremes, evidence/fallback, and stopping rule.
3. Record non-conformance findings with severity and remediation path.
4. Recommend policy-safe improvements with escalation thresholds.
5. Publish a concise decision log for review and auditability.

## Guardrails

- Do not approve out-of-policy changes without documented exception path.
- Do not hide uncertainty in compliance judgments.
- Do not recommend changes without clear ownership and closure criteria.
- Do not conflate style preference with contractual requirement.
- Do not review generic placeholder content alone when representative
  content is available.
- Theme reviews return exact-revision/scope evidence to `theming`; a structural
  fallback review does not clear required visual-evidence gates. Record actual
  changed targets on failure, and never treat a selected theme as write authority.
- Do not perform more than one revision pass inside this workflow; escalate
  further concerns instead of looping indefinitely.
- Defer standalone typography, polish, fit-and-finish, or craft-checklist requests
  to `craft-quality` unless the requested output is a governed review report.

## Output

- Governance report with findings, severity, and remediation owners.
- Decision log with follow-up checkpoints.

## Delegates / pairs with

- craft-quality
- web-usability-review
- visual-regression
