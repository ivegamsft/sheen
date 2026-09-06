---
name: design-review
compatibility: [github-copilot-cli]
description: "Use when critiquing a design artifact against principles, craft standards, or system guidelines. USE FOR: artifact critique, principle-based review, craft issue identification. DO NOT USE FOR: multi-option debate facilitation, full repo audits."
category: governance
metadata:
  category: governance
  maturity: stable
  audience: [designer, developer]
  pillar: governance
allowed-tools: []
---

# design-review

Run craft-bar reviews for a single artifact or flow.

## Workflow
1. Define governed scope, policy expectations, and acceptance criteria.
2. Evaluate artifacts against explicit contracts and standards. Read and apply the [real-content critique loop](references/real-content-critique.md), including state extremes, evidence/fallback, and stopping rule.
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

## Output
- Governance report with findings, severity, and remediation owners.
- Decision log with follow-up checkpoints.

## Delegates / pairs with
- craft-quality
- web-usability-review
- visual-regression
