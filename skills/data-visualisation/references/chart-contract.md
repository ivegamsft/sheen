# Chart Selection, Accessibility, and Output Contract (#63)

Read for every chart/dashboard design or audit. Apply the decision table,
accessibility rules, and output schema; the scenarios illustrate their use.
Example document paths are downstream inputs, not bundled files.

## Chart Type Decision Tree

| Data Relationship | Recommended Chart | Token Set |
|---|---|---|
| Part-to-whole (≤6 parts) | Donut / Pie | `color.data.*` categorical |
| Part-to-whole (>6 parts) | Stacked Bar | `color.data.*` sequential |
| Trend over time | Line / Area | `color.data.series.*` |
| Comparison (few items) | Bar / Column | `color.data.*` categorical |
| Comparison (many items) | Table + Sparkline | `color.data.*` + `motion.none` |
| Correlation | Scatter | `color.data.series.*` |
| Distribution | Histogram / Box | `color.data.neutral` |
| Geo / spatial | Choropleth | `color.data.sequential.*` |

## Sample Prompts

### Choose chart type

```
@data-visualisation recommend a chart type for showing monthly revenue
by product category over 12 months (5 categories)
```

**Output:**
```
Recommended: Grouped Bar Chart (monthly buckets) with line overlay (trend)
Alt: Small multiples (1 line per category) if trends matter more than magnitude

Token bindings:
  color.data.series.1 → category A
  color.data.series.2 → category B
  ...
  motion.duration.none → disable animation for data integrity
  color.data.neutral   → baseline/zero line
```

### Accessibility audit for a chart

```
@data-visualisation audit the chart design in docs/wireframes/dashboard.spec.md
for colour-blind safety and ARIA compliance
```

### Data density spec

```
@data-visualisation specify density rules for a metrics dashboard
with 12 KPI cards, 3 charts, and a data table
```

### Generate data-viz component spec

```
@data-visualisation generate a component spec for a line chart
showing 4 time series with a legend and tooltip
```

## Spec artifact roles

These suggested downstream artifact names are not bundled templates.
Use the decision table, accessibility rules, and schema to author them.

| Template | Purpose |
|---|---|
| `chart-spec-template.md` | Chart component spec: type, axes, series, colours, ARIA |
| `dashboard-layout-template.md` | Dashboard layout spec with density rules and hierarchy |
| `data-colour-palette-template.md` | Accessible colour encoding scheme (8-colour categorical + sequential) |

## Accessibility Rules for Data Visualisation

1. Never encode data meaning with colour alone — add pattern, shape, or label
2. All series colours must pass 3:1 contrast against chart background
3. All axes, legends, and tooltips must have ARIA labels
4. Provide a `<table>` data fallback for all charts (WCAG 1.3.1)
5. Animations must respect `prefers-reduced-motion`

## Output Schema

```yaml
discriminator: component-spec
chart_type: string
series_count: number
colour_encoding: [{series: string, token: string, hex: string}]
aria:
  label: string
  description: string
  table_fallback: boolean
accessibility_pass: boolean
density_rating: low | medium | high | excessive
```
