---
# Experience Index: [Product / Application Name]

> Mode: Audit | Generate · Status: Draft / In review / Accepted
> Owner: [Name/Team] · Last updated: [YYYY-MM-DD]

This is the canonical logical contract (spec §5). It does not replace
`DESIGN.md`, `AESTHETIC-DIRECTION.md`, `.lexicon.md`, the component
inventory, or the pattern library — it indexes and relates them.

---

## 1. Identity and scope

| Field | Value |
|---|---|
| Experience name | |
| Mode | Audit / Generate |
| Status | |
| Scope (platforms, roles, environments) | |
| Primary archetype | see `archetypes.md` |
| Supporting archetype(s) | |
| Audiences and goals | |
| Platforms and contexts | |

---

## 2. Artifact inventory

Every artifact below MUST have a stable, unique ID within this application.
Use links, keys, anchors, or tool-native IDs — any unambiguous mechanism.

| Artifact type | ID prefix (suggested) | Owning specialist skill |
|---|---|---|
| Brief | `brief-*` | this skill |
| Brand | `brand-*` | `brand-identity`, `design-tokens`, `theming` |
| Voice | `voice-*` | `brand-voice-tone`, `ux-writing`, `lexicon` |
| IA | `ia-*` | `information-architecture`, `navigation-design`, `taxonomy` |
| Layout | `layout-*` | `layout-grid-spacing`, `responsive-design`, `app-layout-catalog` |
| Page | `page-*` | `content-hierarchy`, `app-component-catalog` |
| Wireframe | `wf-*` | `wireframing` |
| Flow | `flow-*` | `user-research`, `ux` |

List every artifact instance with: ID, title, status, and the source(s) it
was derived from (observed evidence, accepted design system, brief, or
assumption).

---

## 3. Relationships

Record cross-references so validation (spec §12) can resolve them:

- Every **page** references exactly one **layout** ID.
- Every **flow** step references a **page** ID or a declared external
  touchpoint (name the system/channel, not a page ID).
- Every **wireframe** references exactly one **page** ID.
- Every **archetype**'s required moments map to at least one **page** or
  **flow** ID.

| From | Relationship | To |
|---|---|---|
| `page-*` | uses layout | `layout-*` |
| `flow-*` step N | resolves to | `page-*` or `[external: name]` |
| `wf-*` | shows | `page-*` |
| `archetype moment` | represented by | `page-*` / `flow-*` |

---

## 4. Sources, decisions, assumptions, and open questions

| Type | Description | Reference |
|---|---|---|
| Authoritative source | | link/path |
| Decision | | rationale |
| Assumption (generate mode only) | | why it was needed |
| Unresolved question | | owner |

---

## 5. Generated or rendered views

List any downstream-rendered view (diagram, gallery, prototype) derived from
this logical contract, and note that the logical contract remains
authoritative if they diverge.
