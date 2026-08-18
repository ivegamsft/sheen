---
name: theming
compatibility: [github-copilot-cli]
description: "Use when creating new themes, applying semantic token overrides, or validating theme completeness. USE FOR: new theme creation, semantic overrides, theme completeness validation. DO NOT USE FOR: new semantic key creation, brand voice guidance."
category: foundation
metadata:
  category: foundation
  maturity: stable
  audience: [designer, developer]
  pillar: foundations
allowed-tools: []
---

# theming

Create and validate light/dark/high-contrast/brand themes.

## Workflow
1. Inventory existing primitives, aliases, and constraints for the target surfaces.
2. Define normalized foundation rules (naming, scales, and semantic intent).
3. Produce cross-theme mappings and list deliberate exceptions with rationale.
4. Validate compatibility with related foundations and downstream components.
5. Publish migration notes for safe adoption and backwards compatibility.

## Guardrails
- Do not introduce breaking foundation changes without migration guidance.
- Do not encode one-off product exceptions as global foundation rules.
- Do not bypass accessibility constraints when shaping primitives.
- Do not duplicate semantics already covered by adjacent foundation skills.

## Output
- Foundation decision brief with naming/scales and constraints.
- Impact and migration checklist for affected components and themes.

## Delegates / pairs with
- color-system
- color-contrast-check
