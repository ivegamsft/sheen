---
name: app-layout-catalog
compatibility: [github-copilot-cli]
description: "Use when auditing or generating an application-specific catalog of logical page layouts, mapping pages to layouts, or selecting a layout's regions, navigation placement, and component-role constraints. USE FOR: app layout catalog audits, page-to-layout mapping and variant-vs-drift normalization, layout reuse/extend/create selection, app layout gallery documentation. DO NOT USE FOR: single component anatomy specs, visual theme/token styling, framework/grid/DOM implementation choices."
category: design
metadata:
  category: design
  maturity: draft
  audience: [designer, developer]
  pillar: components
allowed-tools: []
---
# app-layout-catalog

Audit or generate an application-specific catalog of logical page layouts —
regions, navigation placement, and component-role constraints — independent
of framework, grid technology, or DOM structure.

## Workflow
1. Load the app's design system, IA/navigation decisions, Experience
   Blueprint, App Component Catalog, and pattern library as authoritative.
   Use neutral layout-role seeds (narrative landing, focused splash,
   collection/discovery, detail, dashboard, workbench, master-detail, guided
   workflow, form/settings, article, search/results, auth/gateway) only to
   expose structural gaps, never as fixed templates.
2. Audit mode: inventory pages, shells, templates, and responsive states;
   group by structural purpose, region relationships, and navigation (not
   appearance); separate variants from drift, misuse, and duplicate
   layouts; map pages/components to regions with evidence.
3. Generate mode: read the page's purpose, archetype, IA level, navigation,
   data shape, and component needs; search the catalog by purpose, alias,
   and region/navigation constraints; eliminate conflicting candidates.
4. Reuse an existing layout when it fits; extend only when structural
   purpose and region semantics hold; specify a new layout only for a
   distinct, unmet need — never for different content, colors, or
   component instances alone.
5. Complete every metadata area: identity/provenance, usage rules, IA/nav
   applicability, region model, component-role constraints, styling
   abstractions, data needs, responsive behavior, accessibility structure,
   and selection rationale (see `specs/12-app-layout-catalog.spec.md`).
6. Add the accepted layout to the app-specific gallery with its reuse/
   extend/create rationale, rejected alternatives, and evidence.

## Guardrails
- Do not copy another product's layout, navigation, IA, or visual style;
  neutral seeds are gap-detection prompts, not fixed templates.
- Do not prescribe framework, CSS grid/flexbox, breakpoints, DOM structure,
  or gallery/design-tool implementation.
- Do not create a new layout for different content, colors, or component
  instances alone, or let implementation bindings replace the logical spec.
- Do not invent backend fields, APIs, or component behavior owned by the
  App Component Catalog.

## Output
- Logical layout catalog entries with complete identity, usage, IA/
  navigation, region, component-role, styling, data, responsive,
  accessibility, selection, and provenance metadata.
- Audit findings: page-to-layout map, variant-vs-drift classification, and
  evidence-ranked remediation priorities.
- Gallery documentation in the downstream's chosen representation.

## Delegates / pairs with
- information-architecture, navigation-design
- pattern-library, component-spec
- responsive-design, layout-grid-spacing, wireframing
