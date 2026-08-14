---
name: color-system
compatibility: [github-copilot-cli]
description: "Use when this skill is the right fit for the request. Build accessible palette ramps and semantic color roles. USE FOR: generating color ramps, mapping brand hues to semantic roles, validating cross-theme contrast readiness. DO NOT USE FOR: isolated per-pair contrast reporting only, non-color token authoring."
category: foundation
metadata:
  category: foundation
  maturity: stable
  audience: [designer, developer]
  pillar: foundations
allowed-tools: []
---
# Color System

Define color primitives and semantic roles that stay accessible across themes.

## Workflow
1. Establish or refine core palette ramps for neutral and brand hues.
2. Map semantic roles (`primary`, `surface`, `on-*`, state variants) to core.
3. Ensure role consistency across light, dark, and high-contrast themes.
4. Validate required contrast pairs and state legibility.
5. Document rationale for role mappings and tradeoffs.

## Guardrails
- Do not bypass semantic role naming to expose raw color stops directly.
- Do not ship role colors that fail WCAG thresholds.
- Do not add theme-only semantic keys.

## Output
- Updated color ramps and semantic role mappings in token files.
- Contrast-aware role mapping notes for implementation teams.

## Delegates / pairs with
- `design-tokens`, `theming`, `color-contrast-check`
- `accessibility-audit`

