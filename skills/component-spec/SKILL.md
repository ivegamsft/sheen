---
name: component-spec
compatibility: [github-copilot-cli]
description: "Author complete component specifications with anatomy, variants, states, and accessibility behavior, checking the component inventory first to avoid duplicate specs. USE FOR: defining component contracts, documenting ARIA/keyboard behavior, producing implementation-ready redlines. DO NOT USE FOR: whole-system design audits, broad UX strategy documents."
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

1. Check `docs/components/inventory.md` first — if a stable spec already
   exists for this component, link to it instead of re-authoring one.
2. Define component intent, anatomy, and variant boundaries.
3. Specify interaction states (hover, focus, pressed, disabled, error, empty).
4. Map dimensions, spacing, and colors to existing token roles.
5. Document accessibility contract: ARIA role/state, keyboard model, focus behavior.
6. Include usage guidance, anti-patterns, and handoff notes.
7. Add or update the component's row in `docs/components/inventory.md`
   (maturity, spec link, last-reviewed date) so the next team can find it.

## Guardrails

- Do not leave accessibility behavior implicit.
- Do not hardcode visual values when tokens already exist.
- Do not merge multiple unrelated components into one spec.

## Output

- Component specification artifact with variants, states, redlines, and a11y contract.

## Delegates / pairs with

- `ui-states-interaction`, `design-handoff`, `design-tokens`
- `accessibility-audit`
