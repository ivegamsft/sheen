# Worked example: generating a component for a new page context

> Representative scenario for the `app-component-catalog` skill's generate
> mode (spec 11 §10). Fictional sample app: the same internal operations
> console as `audit-scenario.md`.

## Context

- **Task:** a new "bulk export" page needs a way to show export progress
  for up to 500 selected records, in a sidebar region role.
- **Audience:** internal operators, moderate task frequency, desktop-first
  but must remain usable at a narrow viewport.
- **Existing catalog:** `Primary Action` (see `audit-scenario.md`), `Alert`,
  `Progress Indicator (determinate)`, `Notification (toast)`.

## Step-by-step reasoning

1. **Search first** — the catalog already has a determinate
   `Progress Indicator`, used today for single-file uploads.
2. **Eliminate conflicting candidates** — `Notification (toast)` is
   transient and dismissible; the do-not-use rule excludes it for
   long-running, resumable operations the user must keep monitoring.
3. **Reuse vs. extend check** — the existing `Progress Indicator`'s contract
   assumes one tracked item. The new need is N tracked items with per-item
   status (queued/exporting/done/failed). The core purpose (show progress
   toward completion) survives, but the data contract does not — this
   crosses the line from "reuse" to "extend."
4. **Decision** — extend `Progress Indicator` with a new `multi-item` usage
   rule and a required `items[]` data shape (id, label, status), rather than
   specifying a brand-new logical component. A visual difference (a list
   instead of one bar) alone would not have justified even an extension;
   the differing data cardinality and required per-item status did.
5. **Placement test** — sidebar region role allows persistent,
   non-blocking status content; confirmed against the app's layout rules.
6. **Responsive check** — at narrow viewports, per-item rows collapse to a
   single aggregate count and percentage, preserving the "how much is left"
   information; per-item detail remains available on request.

## Recorded decision (sample)

- **Reused / extended / newly specified:** extended.
- **Component:** `Progress Indicator` — added `multi-item` usage rule.
- **Rationale:** the existing component's purpose (communicate progress
  toward completion) matches; only the data cardinality needed to grow.
- **Rejected alternatives:** `Notification (toast)` (wrong persistence
  model), a new `Bulk Operation Tracker` component (no distinct unmet need
  once the data contract was added to the existing entry).
- **Gallery update:** `templates/app-component-catalog/component-entry.md`
  §4 (composition — now allows a repeated per-item row), §6 (data — added
  `items[]` requirement), §8 (responsive — added the narrow-viewport
  aggregate-collapse rule).
