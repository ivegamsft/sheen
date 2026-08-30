---
# [Dashboard Name] Layout Spec

> Status: Draft | Version: 0.1.0 | Owner: [Team] | Last reviewed: [YYYY-MM-DD]

---

## 1. Overview

**Purpose:** [What decision or monitoring task does this dashboard support?]

**Primary audience:** [role, e.g. "on-call engineer", "sales manager"]

**Refresh cadence:** [real-time / polling interval / manual refresh]

---

## 2. Inventory

| # | Widget | Type | Priority |
|---|---|---|---|
| 1 | [KPI: Active users] | KPI card | Primary |
| 2 | [Revenue trend] | Line chart | Primary |
| 3 | [Errors by service] | Bar chart | Secondary |
| 4 | [Raw events] | Data table | Tertiary |

<!-- Add/remove rows. Priority drives layout order and above-the-fold placement. -->

---

## 3. Density rules

| Density rating | Definition | Applies when |
|---|---|---|
| Low | ≤4 widgets, generous whitespace | Executive summary / at-a-glance view |
| Medium | 5-9 widgets, `space.component.gap-md` between cards | Team operational dashboard |
| High | 10-16 widgets, `space.component.gap-sm` between cards | Power-user / NOC dashboard |
| Excessive (avoid) | >16 widgets on one screen | Split into tabs or drill-down views instead |

**This dashboard's density rating:** [Low / Medium / High]

---

## 4. Layout & hierarchy

```text
[Wireframe or grid description, e.g.:]

+------------------+------------------+------------------+------------------+
|   KPI card 1     |   KPI card 2     |   KPI card 3     |   KPI card 4     |
+------------------+------------------+------------------+------------------+
|                     Primary trend chart (full width)                      |
+------------------------------------+---------------------------------------+
|      Secondary chart A              |         Secondary chart B            |
+------------------------------------+---------------------------------------+
|                          Data table (full width)                          |
+-----------------------------------------------------------------------------+
```

**Grid:** `layout.grid.columns` = [12 / 4], gutter = `space.component.gap-md`

**Above the fold:** [Which widgets must be visible without scrolling on the primary target viewport.]

---

## 5. Token bindings

| Element | Property | Token |
|---|---|---|
| Dashboard background | background | `color.background` |
| Card | background | `color.surface` |
| Card | border | `color.border` |
| Card | border-radius | `radius.md` |
| Card | padding | `space.component.padding-md` |
| KPI value | typography | `type.heading-2` |
| KPI label | typography | `type.caption` |
| KPI label | color | `color.muted` |
| Chart baseline | color | `color.data.neutral` |

---

## 6. Colour encoding

- [ ] Chart-level colour encoding follows `chart-spec-template.md` for every chart widget on this dashboard.
- [ ] KPI status colours (good/warn/bad, if used) use `color.success` / `color.warning` / `color.error` — **not** `color.data.*` (chart tokens are for series identity, not status).
- [ ] Theme parity checked across light / dark / high-contrast.

---

## 7. Accessibility

- **Reading order:** DOM order matches visual priority (KPIs → primary trend → secondary → table), independent of CSS grid placement.
- **Landmark/heading structure:** each widget has a heading (`type.label` or higher) associated via `aria-labelledby`.
- **Live regions:** widgets that auto-refresh use `aria-live="polite"` (not `assertive`, to avoid interrupting screen-reader users).
- **Table fallback:** every chart widget provides the WCAG 1.3.1 `<table>` fallback defined in its own chart spec.
- **Reduced motion:** auto-refresh transitions and skeleton loaders respect `prefers-reduced-motion`.

---

## 8. Responsive behaviour

| Breakpoint | Layout change |
|---|---|
| Mobile | Single column; KPI cards become a horizontal scroll strip |
| Tablet | 2-column grid |
| Desktop | Full grid as drawn in §4 |

---

## 9. Empty / loading / error states

| State | Behaviour |
|---|---|
| Loading | Skeleton cards matching final layout dimensions (prevents layout shift) |
| Partial data | Widgets that have data render; widgets without show their own empty state (do not block the whole dashboard) |
| Full error | Dashboard-level banner, `role="alert"`, with retry |

---

## 10. Do / Don't

| Do | Don't |
|---|---|
| Cap primary/above-the-fold widgets to what fits the density rating | Cram >16 widgets onto one screen |
| Use consistent token bindings across every widget | Hand-pick one-off hex per widget |
| Provide a manual refresh affordance even when auto-refresh is on | Force auto-refresh with no way to pause (breaks focus for screen-reader/low-vision users) |
