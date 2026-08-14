---
name: user-research
compatibility: [github-copilot-cli]
description: "Use when this skill is the right fit for the request. USE FOR: research planning, interview/persona synthesis, usability test protocol design. DO NOT USE FOR: heuristic-only reviews, token schema authoring."
category: governance
metadata:
  category: governance
  maturity: beta
  audience: [designer, developer]
  pillar: governance
allowed-tools: []
---

# user-research

Plan and synthesize user research artifacts.

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
- information-architecture
- web-usability-review
