# App Layout Catalog — Selection Scenarios (Reuse / Extend / Create)

> Representative end-to-end scenarios for generate-mode layout selection
> (spec 12 §9–§10). Each scenario traces: page context → catalog search →
> eliminated candidates → decision → gallery update → traceability links to
> the Experience Blueprint page/flow and App Component Catalog entries.

## Scenario 1 — Reuse

**Page context:** A new "Team members" settings page. Purpose: review and
edit a structured list of accounts and roles. Archetype: internal tool. IA
level: section. Navigation: persistent local nav, no global search. Data
shape: bounded collection (< 200 rows), low update frequency. Required
component roles: data table, role-select control, invite action, empty
state.

**Catalog search:** matches the accepted `form-settings` and
`collection-with-inspector` layouts on purpose/IA level; `form-settings` wins
because the task is "review and edit configuration safely," not "browse and
select among many records."

**Eliminated candidates:** `dashboard-overview` (no monitoring/summary need);
`master-detail` (no need to move between many entities and a large content
pane); `operational-workbench` (no live/priority-queue behavior).

**Decision:** **Reuse** `form-settings` unchanged. No new region or
navigation rule needed; the data table and invite-action component roles are
already permitted in its "primary content" and "actions" regions.

**Gallery update:** add "Team members" to `form-settings`'s known page list;
no new catalog entry created.

**Traceability:** Experience Blueprint page `settings/team-members`; flow
`invite-and-assign-role`; App Component Catalog roles `data-table`,
`role-select`, `invite-action`.

---

## Scenario 2 — Extend

**Page context:** An existing `collection-with-inspector` layout is used for
`/orders`. A new requirement adds a **bulk-approval** action bar that must
appear only when multiple rows are selected, without changing the layout's
navigation, IA level, or existing region semantics.

**Catalog search:** `collection-with-inspector` already fits IA level,
navigation, and primary content shape; only the component-placement contract
is incomplete — it has no defined region/rule for a conditional bulk-action
bar.

**Eliminated candidates:** none — no other logical layout differs enough to
consider; the structural purpose is unchanged.

**Decision:** **Extend** `collection-with-inspector`: add an optional,
conditional "bulk actions" region (visible only when selection count > 0,
docked above the primary content region, removed from the reading order when
empty) and document its allowed component roles (bulk-action bar,
confirmation dialog trigger). The layout's IA/navigation/region semantics
otherwise remain intact.

**Gallery update:** update the existing `collection-with-inspector` entry's
region model and component-placement contract; do not create a new layout ID.

**Traceability:** Experience Blueprint flow `bulk-approve-orders`; App
Component Catalog role `bulk-action-bar` (new component-catalog entry,
tracked separately — this skill does not define its internal behavior).

---

## Scenario 3 — Create

**Page context:** A new real-time **operations command center** page must
let on-call staff monitor live incident streams across multiple systems,
triage in priority order, and resolve or escalate without losing situational
context — a fundamentally different task shape than any existing catalog
entry (which are either settings, collection browsing, or single-entity
detail).

**Catalog search:** `dashboard-overview` is close but is monitor-only (no
resolve/triage action model); `operational-workbench` neutral seed most
closely matches, but no app-specific catalog entry exists yet for it.

**Eliminated candidates:** `dashboard-overview` (lacks required
triage/resolve action region and live-priority ordering); `master-detail`
(does not support simultaneous multi-stream monitoring).

**Decision:** **Create** a new `operational-workbench` app-specific layout,
specialized from the neutral seed of the same name. Define its full contract
(regions: live-status summary, priority queue, incident detail/inspector,
resolve/escalate actions, feedback/system status; IA level: task; navigation:
persistent utility nav plus contextual actions; responsive: priority queue
collapses to a routed list before the detail panel; accessibility: live
region announcements for new/escalated incidents).

**Gallery update:** add the new entry with full metadata (spec 12 §6),
reuse/extend/create rationale, and rejected alternatives; link it to the
neutral seed as its point of origin (not a copied template).

**Traceability:** Experience Blueprint page `ops/command-center`; flow
`triage-and-resolve-incident`; App Component Catalog roles `priority-queue`,
`incident-inspector`, `live-status-summary` (new entries, tracked separately).
