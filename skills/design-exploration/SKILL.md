---
name: design-exploration
compatibility: [github-copilot-cli]
description: "Use when this skill is the right fit for the request. USE FOR: concept generation, divergent direction exploration, idea synthesis. DO NOT USE FOR: final decision arbitration, wcag audit reporting."
category: lifecycle
metadata:
  category: lifecycle
  maturity: beta
  audience: [designer, developer]
  pillar: lifecycle
allowed-tools: []
---

# design-exploration

Generate and shape new design concepts.

## Workflow
1. Establish lifecycle objective (audit, exploration, handoff, update, or recommendation).
2. Gather current-state evidence and explicit constraints.
3. Produce decision-ready artifacts using this lifecycle method.
4. Validate compatibility with design system, accessibility, and governance.
5. Sequence next actions with owners, dependencies, and risk notes.

## Guardrails
- Do not make directional claims without evidence collection.
- Do not present exploratory artifacts as final sign-off.
- Do not omit risk/dependency notes for downstream execution.
- Do not duplicate ownership of neighboring lifecycle skills without handoff.

## Output
- Lifecycle artifact set (analysis, decisions, and actions).
- Handoff-ready summary with risks and dependency map.

## Delegates / pairs with
- design-debate
- brand-identity
