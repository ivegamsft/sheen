---
# App Layout Catalog — Audit Finding

> One record per audit-mode observation (spec 12 §8). Copy this file per
> finding, or keep a running findings log with one section per finding using
> the same fields.

## Finding fields (template)

- **Finding ID:** [stable id, e.g. ALC-2026-041]
- **Observed evidence:** [pages, routes, shells, templates, design frames, or
  responsive states examined]
- **Classification:** one of —
  - `variant` — one layout with legitimate, documented variation
  - `drift` — one layout with structural implementation drift
  - `distinct` — multiple layouts with genuinely different purpose
  - `boundary-confusion` — a layout, page, component, pattern, or shell
    conflated with another concept
- **Confidence:** [low | medium | high, with rationale]
- **User impact:** [who is affected and how]
- **Affected pages / components:** [list]
- **Recommended catalog action:** [create | reuse | extend | deprecate | merge | split]
- **Rationale:** [why this action and not an alternative]

---

## Worked example (fixture)

- **Finding ID:** ALC-2026-007
- **Observed evidence:** `/orders`, `/customers`, and `/inventory` pages each
  render a persistent left section list, a page-level filter bar, and a
  paginated table of records with a detail panel that opens on row select.
- **Classification:** `variant` of one **Collection/discovery** logical
  layout — the three pages share region roles (local navigation, filters and
  controls, primary content as a record collection, detail/inspector), the
  same navigation placement, and the same responsive collapse behavior
  (detail panel becomes a routed sub-page below the tablet breakpoint).
  Differences are limited to column sets, filter fields, and record type —
  content differences, not structural differences.
- **Confidence:** high — three independent pages, consistent region and
  navigation evidence, consistent responsive transformation.
- **User impact:** none currently; risk is future duplication if a fourth
  team builds a fourth near-identical page as a "new" layout.
- **Affected pages / components:** `/orders`, `/customers`, `/inventory`;
  record table, filter bar, detail inspector component roles.
- **Recommended catalog action:** `reuse` — register one
  `collection-with-inspector` logical layout entry; map all three pages to
  it; do not create three separate layout entries.
- **Rationale:** the structural purpose and region semantics are identical
  across all three pages; only content and component instances differ,
  which does not justify separate logical layouts (spec 12 §9).

### Contrasting finding (drift, not variant)

- **Finding ID:** ALC-2026-008
- **Observed evidence:** the `/inventory` page's detail panel is missing the
  primary action region present on `/orders` and `/customers`, and its
  filter bar does not participate in the shared keyboard focus order.
- **Classification:** `drift` — same logical layout as ALC-2026-007, but the
  `/inventory` instance omits a required region (actions) and violates the
  documented focus order, rather than expressing a legitimate variant.
- **Confidence:** medium — confirmed by structure inspection; user-impact
  severity needs an accessibility pass to confirm keyboard-trap risk.
- **User impact:** users on `/inventory` cannot commit an action from the
  detail panel without returning to the collection; keyboard users may lose
  a predictable tab order.
- **Affected pages / components:** `/inventory` detail panel and filter bar.
- **Recommended catalog action:** `extend` is not needed — this is not a
  layout gap, it is an implementation bug against the accepted
  `collection-with-inspector` entry; route to engineering/backend-dev to fix
  the page implementation, not to the layout catalog.
