---
name: data-visualisation
compatibility: [github-copilot-cli]
description: "Use when designing charts, graphs, dashboards, or any data-dense UI. USE FOR: choose the right chart type for a data relationship, design a colour encoding scheme for a multi-series chart, specify data density rules for a dashboard layout, audit a chart design for accessibility (colour-blind safe, axis labels, ARIA), generate a data visualisation component spec. DO NOT USE FOR: implementing chart rendering code, data pipeline design, backend analytics query optimisation."
category: usability
metadata:
  category: usability
  maturity: stable
  audience:
    - developer
    - designer
    - data-analyst
  pillar: usability
allowed-tools: []
---
# Data Visualisation Design Skill

Design accurate, accessible charts, dashboards, and data-dense UI aligned with sheen tokens.

## Workflow

1. Establish the data relationship, series count, audience, and density constraints.
2. Read and apply the [chart contract](references/chart-contract.md): chart/token decision table, scenarios, accessibility rules, artifact roles, and schema.
3. Specify chart type, axes, series, colour encodings, legends, tooltips, and dashboard hierarchy/density.
4. Audit accessibility and record pass status; request missing data colour tokens rather than inventing system definitions.

## Guardrails

- Never encode meaning by colour alone: add pattern, shape, or label.
- All series colours require 3:1 contrast against the chart background.
- Give axes, legends, and tooltips ARIA labels; every chart needs a `<table>` fallback (WCAG 1.3.1).
- Respect `prefers-reduced-motion`; preserve data integrity.
- Do not implement rendering code, pipelines, or backend analytics queries.

## Output

- Downstream chart component, dashboard layout, or accessible palette spec.
- Reference `component-spec` schema: chart type, series count, colour/token/hex bindings, ARIA label/description/table fallback, accessibility pass, density rating.

## Delegates / pairs with

- Triggered by: `ux-designer` (dashboard design), `design-reviewer` (chart audit).
- Feeds: `frontend-dev` (implementation), `accessibility-auditor` (colour + ARIA).
- Token source: `design-system-architect` (data colour tokens, if undefined).
