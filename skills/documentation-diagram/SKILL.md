---
name: documentation-diagram
compatibility: [github-copilot-cli]
description: "Use when generating static, skin-aware SVG diagrams for code and product documentation. USE FOR: render a bar/line/sankey/treemap/gantt/kanban/story-map/user-journey/quadrant/fishbone/funnel/org-chart/loop/timeline/venn/security-matrix diagram from a JSON spec, embed an accessible diagram in a docs page, generate a diagram that automatically follows the current theme's diagram skin. DO NOT USE FOR: live/reporting dashboards with real-time data (use skills/data-visualisation), scatter/polar/radar/Wardley-map diagrams (explicitly out of scope, see ADR-006), animated or interactive charts."
category: governance
metadata:
  category: governance
  maturity: stable
  audience:
    - developer
    - technical-writer
    - designer
  pillar: governance
allowed-tools: []
---
# Documentation Diagram Skill

Render static, accessible, skin-aware documentation SVGs without a second style system.

## Workflow

1. Read and apply the [renderer contract](references/renderer-contract.md): all 16 type/schema choices, exclusions, usage/prerequisites, scenarios, accessibility/lint gates, and output schema.
2. Choose an included type and matching [sample](samples/); redirect excluded requests explicitly.
3. From a sheen source checkout, build diagram skins/icons and render the JSON spec with `render-diagram.ps1 -Type <type> -SpecPath <spec> -OutPath <html> [-Theme light|dark|high-contrast]`.
4. Validate the rendered SVG unmodified with geometry lint and slop audit; deliver self-contained HTML for docs embedding.

## Guardrails

- No scatter/polar/radar or live/reporting dashboards: route to `data-visualisation`. Wardley maps unsupported; no animated/interactive charts (ADR-006).
- Read colours from the skin only. No runtime dependencies, Mermaid, CDN fonts, animation, or CSS transitions (ADR-003/005).
- SVG root needs `role="img"`, title/desc, hidden data table (WCAG 1.3.1), and non-colour encoding.
- Preserve all lint gates: ≤9 structural nodes, ≤2 accents, ≤10px radius, no shadows/all-mono hierarchy, and all six connector rules.
- Never hand-edit generated skin/icon build outputs; static output needs no reduced-motion fallback.

## Output

- Self-contained HTML; reference `rendered-diagram` schema with type/theme/path, dimensions, geometry/slop pass status.

## Delegates / pairs with

- Triggered by: `tech-writer`, `backend-dev` / `frontend-dev` (code docs).
- Feeds: `docs-site` (mkdocs embedding).
- Token/skin source: `design-system-architect` (`color.data.*`, #112; skins, #116).
- Sibling: `data-visualisation` (statistical/reporting taxonomy, ADR-004).
