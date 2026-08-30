---
# [Product/Project Name] Data Colour Palette

> Status: Draft | Version: 0.1.0 | Owner: [Team] | Last reviewed: [YYYY-MM-DD]

This template documents the accessible data-colour encoding scheme for charts and
graphs. It does not invent new colours — it is a usage guide over the tokens
already defined in `tokens/semantic/color.tokens.json` (`color.data.*`), resolved
per theme in `tokens/themes/{light,dark,high-contrast}.tokens.json`.

---

## 1. Categorical / series palette (8-colour max)

Use for unordered comparisons (bar charts, multi-series lines, pie/donut ≤6 slices).
`categorical.*` and `series.*` are identical value sets — use whichever name reads
better in context (`categorical` for part-to-whole, `series` for line/trend charts).

| Slot | Token | Light hex | Dark hex | High-contrast hex | Suggested use |
|---|---|---|---|---|---|
| 1 | `color.data.categorical.1` / `.series.1` | `#0969da` | `#2f81f7` | `#1aebff` | First / primary series |
| 2 | `color.data.categorical.2` / `.series.2` | `#bc4c00` | `#d29922` | `#ffb84d` | |
| 3 | `color.data.categorical.3` / `.series.3` | `#1a7f37` | `#3fb950` | `#66ff99` | |
| 4 | `color.data.categorical.4` / `.series.4` | `#6e40c9` | `#bc80ff` | `#cc99ff` | |
| 5 | `color.data.categorical.5` / `.series.5` | `#cf222e` | `#f85149` | `#ff6666` | |
| 6 | `color.data.categorical.6` / `.series.6` | `#0f7b6c` | `#3fc9b4` | `#33ffe6` | |
| 7 | `color.data.categorical.7` / `.series.7` | `#b83280` | `#e0a6cf` | `#ff9dff` | |
| 8 | `color.data.categorical.8` / `.series.8` | `#8a6d3b` | `#c9a876` | `#ffe066` | |

> Hex values above are a snapshot for reference/design mockups only. **Always bind
> to the token name in implementation** — the literal hex is theme-resolved at
> build time by `scripts/build-tokens.ps1` (CSS/JS) or `scripts/build-diagram-skins.ps1`
> (diagram/documentation renders), so it stays correct if a theme changes.

**More than 8 series?** Do not add a 9th hue. Use small multiples (one mini-chart
per category) or aggregate into an "Other" bucket using `color.data.neutral`.

---

## 2. Sequential ramp (5-step)

Use for ordered magnitude encodings: heatmaps, choropleths, single-metric intensity.

| Step | Token | Meaning |
|---|---|---|
| 1 (lowest) | `color.data.sequential.1` | Lowest magnitude / 0-20th percentile |
| 2 | `color.data.sequential.2` | |
| 3 | `color.data.sequential.3` | Midpoint |
| 4 | `color.data.sequential.4` | |
| 5 (highest) | `color.data.sequential.5` | Highest magnitude / 80-100th percentile |

The low end intentionally sits close to the chart background in every theme (a
standard ColorBrewer/sequential-ramp convention) — this is expected, not a bug.
Because of this, **never rely on the sequential ramp alone to encode meaning**:
pair it with a legend, a numeric label, or a direct data label on the highest/
lowest points.

---

## 3. Neutral / baseline

`color.data.neutral` — zero-line, baseline, or unselected/de-emphasised series.
Use this instead of `color.muted` in chart contexts so chart-specific theming
can diverge from UI-text theming if needed later.

---

## 4. Accessibility checklist

- [ ] **Colour-blind safety.** The categorical palette is designed to be
      distinguishable under common colour-vision deficiencies (protanopia,
      deuteranopia, tritanopia) at the hue level, not just by lightness — but
      always pair colour with a second channel (pattern, marker shape, direct
      label) for anything safety- or decision-critical.
- [ ] **Contrast.** Every categorical/series colour is verified ≥3:1 against
      `color.background` / `color.surface` in light, dark, and high-contrast
      themes (see epic #110 / issue #112 verification notes).
- [ ] **Never reuse alert hues for identity.** `color.success` / `color.warning`
      / `color.error` mean UI state (good/caution/bad). Do not reuse them to
      mean "series A" — that overloads a status colour with an identity meaning
      and breaks for users who rely on that association elsewhere in the product.
- [ ] **Theme parity.** Confirm the palette resolves correctly in all three
      themes by running `scripts/build-diagram-skins.ps1` or inspecting
      `dist/tokens/sheen.css`.

---

## 5. Do / Don't

| Do | Don't |
|---|---|
| Reference `color.data.*` tokens by name | Hard-code the hex values from the table above into product code |
| Use the sequential ramp for one ordered metric | Use the sequential ramp to distinguish >2 unrelated categories |
| Cap categorical series at 8, then switch pattern (small multiples) | Silently drop to a 9th, unverified hue |
