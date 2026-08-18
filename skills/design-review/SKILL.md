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
- craft-quality
- web-usability-review
