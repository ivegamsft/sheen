---
name: app-component-catalog
compatibility: [github-copilot-cli]
description: "Audit or generate one application's logical UI component catalog: neutral seed vocabulary, alias normalization, variant-versus-drift findings, and reuse/extend/create selection. USE FOR: app-specific component audits, alias and duplicate normalization, reuse-extend-create selection decisions, logical component metadata and gallery documentation. DO NOT USE FOR: authoring one component's full anatomy spec, multi-component pattern composition, page-layout region catalogs."
category: design
metadata:
  category: design
  maturity: draft
  audience: [designer, developer]
  pillar: components
allowed-tools: []
---
# app-component-catalog

Audit or select application-specific logical components with evidence, alias normalization, and reuse/extend/create rationale.

## Workflow
1. Read and apply the [catalog contract](references/catalog-contract.md), including both mode checklists, neutral seeds, full metadata, and shared source resources.
2. Load the app's authoritative design system, Experience Blueprint, layouts, and shared/pattern inventories.
3. Audit: inventory bindings/assets/page usage; group by purpose, semantics, and alias evidence; classify variants, drift, or distinct components, with confidence and impact.
4. Generate: capture task/audience/region/data/state/accessibility; search by name/alias/role/constraints and reject conflicting candidates.
5. Reuse when fitting; extend only if core purpose survives; create only for a distinct unmet need. Complete all metadata and gallery provenance, including rejected alternatives.

## Guardrails
- Downstream design decisions are authoritative; neutral seeds expose gaps, never require inventory. Rename, merge, or drop families to fit.
- Never copy another library's components, code, or visuals, or create for visual differences alone.
- A binding cannot replace a logical contract; distinguish components, patterns, regions, and pages.
- Flag ambiguous aliases, undocumented dependencies, one-offs, and mobile behavior dropping the primary task.

## Output
- Downstream logical catalog entries with complete metadata and gallery placement.
- Audit: evidence/confidence/impact/affected-page findings and recommended actions.
- Generate: accepted entry, selection rationale, provenance, rejected alternatives.

## Delegates / pairs with
- `component-spec`, `pattern-library`, `design-system-audit`
- `information-architecture`, `navigation-design`, `responsive-design`
- agent: `design-system-architect`
