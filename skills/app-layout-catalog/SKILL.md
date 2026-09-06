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

Audit or generate logical page layouts, regions, navigation placement, and component-role constraints.

## Workflow
1. Read and apply the [layout contract](references/layout-contract.md): neutral seeds, mode checklists, full metadata, and source spec.
2. Load authoritative app design system, IA/navigation, Experience Blueprint, App Component Catalog, and patterns.
3. Audit pages/shells/templates/responsive states by structural purpose, region relationships, and navigation; separate variants, drift, misuse, duplicates; map pages/components to regions with evidence.
4. Generate: capture purpose/archetype/IA/nav/data/component needs; search by purpose/alias/region/nav constraints, eliminating conflicts.
5. Reuse if fitting; extend only with preserved structural purpose/region semantics; create only for distinct unmet need. Complete every metadata area and gallery rationale, rejected alternatives, and provenance.

## Guardrails
- Neutral seeds expose gaps, not fixed templates; never copy another product's layout, navigation, IA, or style.
- Do not prescribe framework, grid/flexbox, breakpoints, DOM, gallery, or design-tool implementation.
- Do not create layouts for content, colours, or component instances alone, or replace logical specs with bindings.
- Do not invent backend fields, APIs, or component behavior owned by App Component Catalog.

## Output
- Downstream logical layout entries: identity/provenance, usage, IA/nav, regions, component roles, styling abstractions, data, responsive/accessibility structure, selection.
- Audit page-to-layout map, variant/drift classification, evidence-ranked remediation.
- Gallery documentation in the downstream's chosen representation.

## Delegates / pairs with
- information-architecture, navigation-design
- pattern-library, component-spec
- responsive-design, layout-grid-spacing, wireframing
