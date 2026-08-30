---
# [Chart Name] Spec

> Status: Draft | Version: 0.1.0 | Owner: [Team] | Last reviewed: [YYYY-MM-DD]

---

## 1. Overview

**Data relationship:** [Part-to-whole / Trend over time / Comparison / Correlation / Distribution / Geo-spatial]

**Chart type:** [Bar / Line / Donut / Scatter / Histogram / Choropleth / ...] — see
`skills/data-visualisation/SKILL.md` chart-type decision tree.

**When to use it:** [Describe the analytical question this chart answers.]

**When not to use it:** [Name the chart type(s) that would misrepresent this data — e.g. pie for >6 parts.]

---

## 2. Axes & scale

| Axis | Field | Type | Scale | Format |
|---|---|---|---|---|
| X | [field name] | [categorical / temporal / linear] | [linear / log / time] | [e.g. `MMM YYYY`] |
| Y | [field name] | [quantitative] | [linear / log] | [e.g. `$#,##0`] |

**Zero baseline:** [Yes / No — if No, justify why truncating the axis does not mislead.]

---

## 3. Series

| Series | Data field | Token | Notes |
|---|---|---|---|
| 1 | [field] | `color.data.series.1` | |
| 2 | [field] | `color.data.series.2` | |
| 3 | [field] | `color.data.series.3` | |
| ... up to 8 | | `color.data.series.N` | Categorical set is 8-colour max; beyond 8, use small multiples instead of a 9th hue |

For part-to-whole or magnitude/heatmap encodings, use the sequential ramp instead of categorical series:

| Step | Meaning | Token |
|---|---|---|
| Lowest | [e.g. 0-20th percentile] | `color.data.sequential.1` |
| ... | ... | `color.data.sequential.2`-`4` |
| Highest | [e.g. 80-100th percentile] | `color.data.sequential.5` |

**Baseline / zero-line / unselected series:** `color.data.neutral`

---

## 4. Colour encoding

- [ ] No data meaning is encoded by colour alone — paired with [pattern / shape / direct label].
- [ ] All series colours pass **3:1 contrast** against the chart background (`color.background` / `color.surface`).
- [ ] Colour-blind safety checked (categorical palette is colour-blind-conscious by design — see `color.data.*` in `tokens/semantic/color.tokens.json`).
- [ ] Theme coverage confirmed for light / dark / high-contrast (`tokens/themes/*`).

---

## 5. Legend

**Position:** [top / right / bottom / inline]

**Interaction:** [static / click-to-isolate-series / hover-to-highlight]

| Series | Label | Token swatch |
|---|---|---|
| 1 | [label] | `color.data.series.1` |
| ... | | |

---

## 6. ARIA & accessibility

- **`role`:** `img` (static) or `figure` with `aria-describedby` (interactive)
- **`aria-label`:** "[One-sentence chart summary, e.g. 'Bar chart of monthly revenue by product category, Jan-Dec 2026']"
- **Table fallback (WCAG 1.3.1):** [Yes — required] `<table>` with the same data, visually hidden or in a "View as table" disclosure.
- **Keyboard:** legend items and data points that trigger interaction must be focusable and operable via Enter/Space.
- **Reduced motion:** entry animation and transitions respect `prefers-reduced-motion`; use `motion.duration.none` when `prefers-reduced-motion: reduce`.

---

## 7. Tooltip

**Trigger:** [hover / focus / tap]

**Content:** [field 1]: [value] · [field 2]: [value]

**Dismissal:** [Escape / blur / tap-away]

---

## 8. Empty / loading / error states

| State | Behaviour |
|---|---|
| Loading | [Skeleton / spinner], `aria-busy="true"` |
| Empty | "[No data for the selected range.]" + one actionable step |
| Error | "[Could not load chart data.]" + retry action, `role="alert"` |

---

## 9. Responsive behaviour

| Breakpoint | Change |
|---|---|
| Mobile | [e.g. Rotate to horizontal bars / stack legend below] |
| Tablet | [e.g. Reduce tick label density] |
| Desktop | [Full layout] |

---

## 10. Do / Don't

| Do | Don't |
|---|---|
| Use `color.data.categorical.*` for unordered comparisons | Reuse alert hues (`color.error`, `color.warning`) to mean "bad"/"good" in a chart — those are UI-state tokens, not chart tokens |
| Provide a `<table>` fallback | Ship a chart with colour as the only encoding of meaning |
| Cap categorical series at 8 | Add a 9th ad-hoc hue outside `color.data.*` |
