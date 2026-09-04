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

Audit an application's existing UI into an evidence-linked logical component
catalog, or select, extend, or specify a component for a page/layout need.
Implements `specs/11-app-component-catalog.spec.md` (ADR-011). The downstream
design system is authoritative; the neutral seed vocabulary only detects
gaps — rename, merge, or drop families to fit the app. Never copy another
library's components, code, or visuals.

## Neutral seed families

Actions, input/selection, navigation, feedback/status, disclosure/overlays,
content/media, data display, structure, task composition. See
`docs/components/app-component-catalog.md` for the full role table and
`templates/app-component-catalog/component-entry.md` for the logical
component metadata template.

## Audit workflow

1. Load the app's design system, Experience Blueprint, layout catalog, and
   shared/pattern inventories.
2. Inventory implementation bindings, design assets, and observed page usage
   in the stated scope.
3. Group candidates by purpose, semantics, and alias evidence — not
   appearance or name alone — to normalize duplicate labels.
4. Classify each group as one component with legitimate variants,
   implementation drift, or genuinely distinct components; distinguish a
   component from a pattern, a layout region, and a page.
5. Record findings with evidence, confidence, impact, affected pages, and a
   recommended catalog action.

## Generate workflow

1. Read the audience, task, page/layout region, data, state, and
   accessibility context.
2. Search the catalog by name, alias, role, and constraint; eliminate
   candidates whose do-not-use, placement, data, or responsive rules
   conflict.
3. Reuse a fitting component; extend only if its core purpose survives;
   specify a new one only for a distinct unmet need — never for a visual
   difference alone.
4. Complete identity, usage, placement, composition, styling abstractions,
   data/content, behavior/states, and responsive metadata.
5. Add the accepted entry to the app gallery with provenance and document
   why it was reused, extended, or created, plus rejected alternatives.

## Guardrails

- Do not let an implementation binding stand in for the logical contract.
- Do not treat the seed vocabulary as a required inventory.
- Flag ambiguous aliases, undocumented dependencies, one-off components, and
  mobile behavior that drops the primary task.

## Output

- Logical component catalog entries (audit) or a new/updated entry with
  selection rationale and gallery placement (generate).

## Delegates / pairs with

- `component-spec`, `pattern-library`, `design-system-audit`
- `information-architecture`, `navigation-design`, `responsive-design`
- agent: `design-system-architect`
