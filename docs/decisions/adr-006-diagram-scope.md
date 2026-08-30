# ADR-006 — Documentation Diagram Scope: Included vs. Excluded Types

| Field | Value |
|---|---|
| **Date** | 2026-08-30 |
| **Status** | Accepted |
| **Deciders** | sheen maintainers |
| **Supersedes** | — |
| **Superseded by** | — |

## Context

The original audit comparing this repo to `cathrynlavery/diagram-design`
found a much broader universe of chart/diagram types than a documentation
site actually needs. Epic #110's design debate had to decide, explicitly,
which types belong in the documentation-diagram capability (#113) and which
do not, rather than attempting to support every chart type a general
data-visualisation tool might offer.

The debate centred on one criterion: **does this diagram describe structure,
flow, or process for code/docs (a documentation concern), or does it report
live/measured data (an analytics/dashboard concern)?** Documentation diagrams
are authored once and read many times as static reference material; reporting
charts are bound to live or frequently-refreshed datasets and belong with
the data-visualisation/dashboard tooling (`skills/data-visualisation/`), not
the documentation renderer.

## Options Considered

### Option 1 — Support the full reference-project type list
Include every chart/diagram type the audited reference project supports
(scatter, polar, radar/spider, Wardley maps, live dashboards, etc.) alongside
structural/process diagrams.

- ✅ Maximum coverage, no gaps
- ❌ Conflates two different consumption models (static reference vs. live
  reporting) into one renderer, contradicting ADR-003's static-by-default
  posture for the wrong reason (reporting charts need live data by design)
- ❌ Massively expands #113's already-large scope (35 types) with types that
  duplicate `skills/data-visualisation/` templates already delivered under #119

**Score: 3/10**

### Option 2 — Scope to structure/process/flow diagrams only; route reporting elsewhere *(chosen)*
Include only diagram types whose purpose is describing the structure, flow,
process, or relationships of a system/codebase for documentation purposes.
Explicitly exclude chart types whose purpose is reporting measured/live data
— those remain specs in `skills/data-visualisation/` (chart-spec-template,
dashboard-layout-template), not renderer types.

**Included types (16, decided this epic):**
Bar, Line, Sankey, Treemap, Gantt, Kanban, Story map, User journey, Quadrant,
Fishbone, Pyramid/funnel, Org chart, Loop/flywheel, Timeline, Venn, DP
security matrix.

**Explicitly excluded from the documentation-diagram renderer:**
Scatter plots, Polar/Radar (spider) charts, Wardley maps, and any live or
frequently-refreshed reporting dashboard. These stay as data-visualisation
specs (already covered by #119's templates) rather than renderer types,
because their value depends on live/measured datasets, not on static
structural documentation.

- ✅ Keeps the renderer's scope aligned with its actual audience (developers
  reading docs), not general BI/reporting
- ✅ Avoids duplicate ownership — reporting-shaped charts already have a home
  in `skills/data-visualisation/`
- ✅ Bounds #113 to a scope that can be delivered with real fixtures/lints per
  type rather than a superficial pass over 35+ types

**Score: 9/10**

### Option 3 — No structural/reporting distinction; scope purely by "what's easy to render statically"
Include whatever renders cleanly as static SVG, regardless of its
structural-vs-reporting nature.

- ✅ Simple filter to apply
- ❌ Scatter/bar/line charts *can* render statically too — this criterion
  doesn't actually separate documentation diagrams from reporting charts,
  so it fails to resolve the original ambiguity

**Score: 4/10**

## Decision

**Adopt Option 2.** The documentation-diagram renderer (#113) supports
exactly the 16 included types above. Scatter, Polar/Radar, Wardley maps, and
any live/reporting dashboard are explicitly out of scope for the renderer and
must route users to `skills/data-visualisation/` instead.

## Consequences

- **Positive:** #113 has a bounded, delivery-sized scope instead of an
  open-ended "support everything" mandate.
- **Positive:** No duplicate ownership between the renderer and
  `skills/data-visualisation/` for reporting-shaped charts.
- **Positive:** Aligns with ADR-004 — each included type maps to a distinct
  semantic pattern (hierarchy, sequence, part-to-whole, flow, timeline,
  comparison, prioritisation) rather than a reporting/measurement concern.
- **Risk:** A future request for "just add scatter plots to the doc
  renderer" will recur. The renderer's entry point (and #113's own docs) must
  surface a clear message routing such requests to
  `skills/data-visualisation/` rather than silently declining or bolting the
  type on.

## Related

- Epic #110, issue #113 (documentation-diagram renderer)
- Issue #119 / `skills/data-visualisation/` templates (reporting charts' home)
- ADR-004 (taxonomy discipline)
