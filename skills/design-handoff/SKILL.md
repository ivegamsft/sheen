---
name: design-handoff
compatibility: [github-copilot-cli]
description: "Use when packaging and preparing design artifacts for engineering handoff, including redlines, annotations, and token exports. USE FOR: engineering handoff packaging, redline and annotation bundling, token/spec export preparation. DO NOT USE FOR: authoring core component specs, backend implementation."
category: lifecycle
metadata:
  category: lifecycle
  maturity: stable
  audience: [designer, developer]
  pillar: lifecycle
allowed-tools: []
---

# design-handoff

Package design artifacts for engineering execution.

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
- component-spec
- design-tokens
