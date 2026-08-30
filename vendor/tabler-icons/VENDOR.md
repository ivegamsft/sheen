# Vendored: tabler-icons (curated subset)

This directory is a **curated, vendored subset** of
[Tabler Icons](https://github.com/tabler/tabler-icons) (MIT), used to
annotate node types in the documentation-diagram renderer (epic #110,
issue #111) — e.g. a person icon on an org-chart node, a shield-lock icon
on a DP security-matrix cell.

Unlike `vendor/basecoat/` (a full pinned mirror), this is a **hand-picked
subset**: only the icons actually referenced by the 16 diagram types kept
under epic #110's scope decision (see
[`docs/decisions/adr-006-diagram-scope.md`](../../docs/decisions/adr-006-diagram-scope.md))
are vendored — not the full ~5,900-icon upstream set.

## Provenance

| Field | Value |
|---|---|
| Source | https://github.com/tabler/tabler-icons |
| Commit | `5a0fe38e97784d94279ce4eb1bf85f9a91bf027e` |
| Vendored on | 2026-08-30 |
| License | MIT — see [`LICENSE`](LICENSE); tracked in [`THIRD_PARTY_LICENSES.md`](../../THIRD_PARTY_LICENSES.md) |
| Variant | `outline` (24×24, `stroke="currentColor"`, 2px stroke) — chosen because
  `currentColor` lets an icon inherit the diagram-skin `ink`/`muted`/`accent`
  role via CSS `color`, with zero per-icon hex, matching ADR-005 (skin is a
  token-generated bridge, never hand-picked hex). |

## What is included

19 icons in `icons/outline/`, one (or a small support set) per kept diagram
type:

| Diagram type | Icon file | Role |
|---|---|---|
| Bar | `chart-bar.svg` | Type marker |
| Line | `chart-line.svg` | Type marker |
| Sankey | `chart-sankey.svg` | Type marker |
| Treemap | `chart-treemap.svg` | Type marker |
| Gantt | `calendar-time.svg` | Type marker (no dedicated upstream "gantt" icon exists) |
| Kanban | `layout-kanban.svg` | Type marker |
| Story map | `route.svg` | Type marker |
| User journey | `map.svg` | Type marker |
| Quadrant | `grid-dots.svg` | Type marker |
| Fishbone | `category.svg` | Type marker |
| Pyramid/funnel | `chart-funnel.svg` | Type marker |
| Org chart | `hierarchy-2.svg` | Type marker |
| Loop/flywheel | `refresh.svg` | Type marker |
| Timeline | `timeline.svg` | Type marker |
| Venn | `circles.svg` | Type marker |
| DP security matrix | `shield-lock.svg` | Type marker |
| *(support)* | `users.svg` | Generic person/role node (org chart, user journey personas) |
| *(support)* | `database.svg` | Generic data-store node (DP security matrix, Sankey) |
| *(support)* | `lock.svg` | Generic access-control annotation (DP security matrix) |

## What is intentionally excluded

- The remaining ~5,880 upstream Tabler icons not referenced by a kept
  diagram type.
- Devicon (tech/language logos) and Simple Icons (brand logos) — these were
  relevant to the *Architecture / Deployment / Data-platform* diagram types,
  which were **dropped** from scope (see ADR-006 and the epic's later scope
  narrowing to the 16 delivery/planning/analysis types). Revisit if those
  types return to scope.

## Update policy

- Treat this tree as **read-only**, same as `vendor/basecoat/`. To add or
  update an icon, re-run `scripts/build-icons.ps1 -Add <icon-name>` (fetches
  from the pinned upstream commit) rather than hand-editing SVGs.
- Bump the Provenance commit above when the pinned upstream ref changes, and
  note it in the repo `CHANGELOG.md`.
- Any new icon added here must also get a row in the table above and, if it
  represents a new upstream project (not Tabler), a new entry in
  `THIRD_PARTY_LICENSES.md`.
