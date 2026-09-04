# ADR-012 — Neutral Layout Seeds Plus App-Specific Logical Gallery

| Field | Value |
|---|---|
| **Date** | 2026-09-04 |
| **Status** | Accepted |
| **Deciders** | sheen maintainers |
| **Supersedes** | — |
| **Superseded by** | — |

## Context

Issue #170 asks for an agent that can audit, generate, and document reusable
logical page layouts for one application. The catalog must tell agents how
navigation and IA level affect selection, which component roles fit each
region, where a layout should and should not appear, and how the structure
adapts to data and responsive contexts.

The layout feature sits between the Experience Blueprint and App Component
Catalog:

- the Experience Blueprint defines required pages, tasks, IA, navigation, and
  flows;
- the layout catalog defines reusable page-region structures;
- the component catalog defines logical units that can occupy those regions.

The decision must avoid fixed templates while also preventing every page from
inventing a new structure.

## Decision criteria

| Criterion | Weight |
|---|---:|
| Honors downstream design system, IA, and navigation | 25% |
| Reliable layout selection and component placement | 20% |
| Audit/generation parity | 15% |
| Responsive and accessibility coherence | 15% |
| Reuse and drift prevention | 10% |
| Gallery discoverability | 10% |
| Implementation neutrality | 5% |

Scores use a 1–5 scale.

## Options considered

### Position A — Fixed page template library

Publish a set of complete page templates for home, dashboard, commerce,
control tower, settings, and other experiences.

- Fast to preview and easy to copy.
- Conflates experience archetype, layout, page content, components, and style.
- Imports assumptions that conflict with downstream IA and navigation.
- Produces superficial similarity rather than task-fit structures.
- Becomes framework- and breakpoint-specific quickly.

### Position B — Generate every page layout freeform

Let the agent create a bespoke arrangement for each page from its prompt with
no app-specific reusable catalog.

- Maximizes local flexibility.
- Repeats equivalent structures under different names.
- Produces inconsistent navigation and region semantics.
- Makes responsive and accessibility behavior difficult to govern.
- Gives component placement no stable contract.

### Position C — Neutral layout seeds plus app-specific logical gallery

Use neutral layout families as discovery prompts, then derive an app-specific
catalog of logical region structures from the downstream design system, IA,
navigation, Experience Blueprint, component catalog, evidence, and product
needs.

- Avoids blank-page invention without prescribing fixed templates.
- Gives audit and generation one logical contract.
- Separates layouts from pages, components, patterns, styling, and bindings.
- Enables selection by task, IA level, navigation, data shape, and region need.
- Makes responsive transformation and accessibility structure explicit.
- Requires disciplined region vocabulary and cross-catalog validation.

## Weighted comparison

| Criterion | Weight | A | B | C |
|---|---:|---:|---:|---:|
| Downstream fit | 25 | 2 | 4 | 5 |
| Selection and placement | 20 | 3 | 1 | 5 |
| Audit/generation parity | 15 | 2 | 2 | 5 |
| Responsive/accessibility coherence | 15 | 2 | 1 | 5 |
| Reuse and drift prevention | 10 | 3 | 1 | 5 |
| Discoverability | 10 | 5 | 1 | 5 |
| Implementation neutrality | 5 | 2 | 4 | 5 |
| **Weighted score / 5** | **100** | **2.70** | **2.20** | **5.00** |

## Decision

**Adopt Position C.** The layout capability will specify agent behavior for:

1. starting from the downstream design system, IA, navigation, and evidence;
2. using neutral layout-role seeds only to detect gaps and prompt reasoning;
3. maintaining an app-specific logical layout catalog;
4. defining named regions and logical component-role constraints;
5. documenting usage, prohibited usage, navigation placement, IA
   applicability, styling abstractions, data needs, responsive transformation,
   accessibility structure, and provenance;
6. presenting the catalog as a composable gallery in the downstream's chosen
   representation.

Sheen will not prescribe a layout technology, framework, exact grid, breakpoint
set, DOM structure, design-tool frame, or gallery implementation.

## Consequences

- **Positive:** Pages gain consistent, explainable structural choices without
  being forced into generic templates.
- **Positive:** Component placement can be checked against region roles rather
  than guessed from visual coordinates.
- **Positive:** Navigation and IA decisions become first-class layout
  constraints.
- **Positive:** Responsive behavior describes task-preserving transformation,
  not only viewport widths.
- **Cost:** The application must maintain logical layout metadata and map pages
  to layouts.
- **Risk:** Neutral seeds can become a fixed template catalog. Spec 12 requires
  consumers to remove, combine, rename, or specialize them.
- **Risk:** Region-role metadata can become too abstract. Each entry must
  include concrete page applicability and component-role examples from the
  downstream application.

## Related

- `specs/12-app-layout-catalog.spec.md`
- [App Layout Catalog guide](../guides/app-layout-catalogs.md)
- ADR-010 (Experience Blueprint agent contract)
- ADR-011 (App Component Catalog)
- Issue #170
