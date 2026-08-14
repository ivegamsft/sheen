---
name: component-spec
compatibility: [github-copilot-cli]
description: "Use when this skill is the right fit for the request. Author complete component specifications with anatomy, variants, states, and accessibility behavior. USE FOR: defining component contracts, documenting ARIA/keyboard behavior, producing implementation-ready redlines. DO NOT USE FOR: whole-system design audits, broad UX strategy documents."
category: design
metadata:
  category: design
  maturity: stable
  audience: [designer, developer]
  pillar: components
allowed-tools: []
---
# Component Spec

Produce a complete, implementation-ready spec for one UI component.

## Workflow
1. Define component intent, anatomy, and variant boundaries.
2. Specify interaction states (hover, focus, pressed, disabled, error, empty).
3. Map dimensions, spacing, and colors to existing token roles.
4. Document accessibility contract: ARIA role/state, keyboard model, focus behavior.
5. Include usage guidance, anti-patterns, and handoff notes.

## Guardrails
- Do not leave accessibility behavior implicit.
- Do not hardcode visual values when tokens already exist.
- Do not merge multiple unrelated components into one spec.

## Output
- Component specification artifact with variants, states, redlines, and a11y contract.

## Delegates / pairs with
- `ui-states-interaction`, `design-handoff`, `design-tokens`
- `accessibility-audit`

