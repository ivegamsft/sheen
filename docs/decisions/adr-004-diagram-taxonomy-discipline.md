# ADR-004 — Diagram Taxonomy: Semantic Pattern vs. Layout Type

| Field | Value |
|---|---|
| **Date** | 2026-08-30 |
| **Status** | Accepted |
| **Deciders** | sheen maintainers |
| **Supersedes** | — |
| **Superseded by** | — |

## Context

The documentation-diagram capability (#113) covers a curated set of 16 diagram
kinds (Bar, Line, Sankey, Treemap, Gantt, Kanban, Story map, User journey,
Quadrant, Fishbone, Pyramid/funnel, Org chart, Loop/flywheel, Timeline, Venn,
DP security matrix — the set decided under this epic's scope debate). As the
renderer grows, contributors will be tempted to add "one more type" for every
new visual shape a diagram tool supports (e.g., separate `radial-org-chart`
vs `org-chart`, or `swimlane-flowchart` vs `flowchart`), even when the
underlying *behavior* the diagram communicates is identical and only the
arrangement of nodes on the canvas differs.

Without a rule, the taxonomy grows unboundedly and two problems follow:
each new "type" needs its own skin mapping, lint fixture, and doc page even
when it adds no new semantic capability, and authors can no longer predict
which type to reach for because near-duplicate types compete.

## Options Considered

### Option 1 — One type per distinct visual layout
Every distinguishable arrangement (radial org chart, horizontal org chart,
compact org chart, ...) is its own registered diagram type.

- ✅ Maximal fidelity to what a specific reference tool renders
- ❌ Unbounded taxonomy growth; type count scales with layout permutations,
  not with communicative intent
- ❌ Every layout variant re-triggers the full lint/skin/doc/fixture cost

**Score: 3/10**

### Option 2 — Semantic pattern drives the type; layout is a rendering detail *(chosen)*
A diagram **type** is defined by the semantic pattern it communicates (e.g.,
"hierarchy", "sequence-over-time", "part-to-whole") — not by its concrete
layout. Layout variations (radial vs. horizontal org chart, horizontal vs.
vertical Gantt) are **rendering options** of the same type, not new types.
The taxonomy only grows when a genuinely new semantic pattern is needed that
none of the existing 16 types can express, and that addition goes through the
same scope decision this epic used (see ADR-006).

- ✅ Taxonomy size tracks communicative intent, which is bounded and already
  enumerated (16 types)
- ✅ New layout requests become renderer options on an existing type instead
  of new epics
- ✅ Matches how the templates in `skills/data-visualisation/` already
  separate "what pattern to use" (chart-spec-template) from "how it's laid
  out" (dashboard-layout-template)
- ❌ Requires a judgment call at proposal time on whether a request is a new
  pattern or a layout variant — mitigated by requiring that judgment call be
  written down (see Governance Rule below)

**Score: 9/10**

### Option 3 — No formal taxonomy; ad hoc per PR
Each PR decides informally whether its diagram is a new type.

- ✅ No process overhead
- ❌ Exactly the drift this ADR exists to prevent

**Score: 2/10**

## Decision

**Adopt Option 2.** Diagram *types* are defined by the semantic pattern they
communicate; layout is a rendering detail of a type, not a new type.

### Governance Rule

When a contributor proposes what looks like a new diagram type:

1. State the semantic pattern it communicates in one sentence.
2. Check it against the 16 accepted types' patterns (documented in
   `skills/documentation-diagram/SKILL.md`, once #113 lands). If an existing
   type's pattern already covers it, the request is a **layout/rendering
   option** of that type — implement it as a renderer parameter, not a new
   type.
3. Only if no existing pattern covers it does it qualify as a genuinely new
   type, and it must go through the same scope-decision rigor as ADR-006
   (explicit include/exclude debate, not silent addition).

## Consequences

- **Positive:** The type count for the documentation-diagram renderer stays
  at the deliberately-scoped 16 unless a real new communicative need arises.
- **Positive:** Skin mapping, lint fixtures, and docs are written once per
  semantic pattern, not once per layout permutation.
- **Risk:** The "is this a new pattern or a layout variant" judgment call is
  subjective at the margins. Mitigated by requiring the one-sentence pattern
  statement in rule 1 above to be recorded in the proposing issue/PR, so
  reviewers can hold future proposals to the same bar.

## Related

- Epic #110, issue #113 (documentation-diagram renderer)
- ADR-006 (diagram scope: included vs. excluded types)
- `skills/data-visualisation/chart-spec-template.md`,
  `dashboard-layout-template.md`
