---
name: design-system-audit
compatibility: [github-copilot-cli]
description: "Use when auditing design-system health across tokens, components, documentation, and adoption patterns. USE FOR: token/component coherence checks, system-level consistency audits, cross-component drift triage. DO NOT USE FOR: exact live DOM/CSS parity reports, repo-wide UX debt triage, new system bootstrap."
category: design
metadata:
  category: design
  maturity: stable
  audience: [designer, developer]
  pillar: components
allowed-tools: []
---

# design-system-audit

Audit a design system for cross-component consistency, coherence, and adoption drift.

## Workflow

1. Clarify scope and expected outcomes.
2. Produce a concrete skill-domain artifact.
3. Validate against adjacent sheen standards.
4. Deliver prioritized actions and handoff notes.

## Guardrails

- Stay within explicit skill scope.
- Avoid unsupported quality/compliance claims.
- Route exact spec-vs-live implementation parity for one component or page to
  `design-drift-detection`.

## Output

- Skill-domain artifact bundle with prioritized actions.

## Delegates / pairs with

- design-tokens
- design-audit
- design-drift-detection for exact implementation parity
