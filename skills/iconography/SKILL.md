---
name: iconography
compatibility: [github-copilot-cli]
description: "Use when this skill is the right fit for the request. USE FOR: icon grid definition, stroke and sizing rules, icon naming taxonomy. DO NOT USE FOR: logo standards, full brand identity."
category: foundation
metadata:
  category: foundation
  maturity: beta
  audience: [designer, developer]
  pillar: foundations
allowed-tools: []
---

# iconography

Define a coherent icon system and naming discipline.

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
- taxonomy
- brand-identity
