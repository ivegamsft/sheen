# Performance Budgets and Assessment Contract (#62)

Read before assessment. Use the complete threshold table, scenarios, and
output schema for hero images, font loading, motion tokens, and page scoring.
Example token/spec paths are downstream inputs; sample estimates are not
measurements of the current application.

## Core Web Vitals Cheatsheet

| Metric | Good | Needs Work | Poor | Design Trigger |
|---|---|---|---|---|
| LCP | ≤ 2.5s | 2.5–4s | > 4s | Hero image size, font blocking |
| CLS | ≤ 0.1 | 0.1–0.25 | > 0.25 | Missing aspect ratios, late font swap |
| INP | ≤ 200ms | 200–500ms | > 500ms | Animation duration tokens |
| FID | ≤ 100ms | 100–300ms | > 300ms | Long animation chains on interaction |

## Sample Prompts

### Assess a design choice

```
@performance-aware-design assess: hero image at 1920px wide with a custom display font
loaded via @font-face. Will this impact LCP?
```

**Output:**
```
## Performance Assessment: Hero + Font

LCP Risk: HIGH
- Hero image: 1920px → estimated 400–900KB unoptimised. Recommend: WebP, max 600KB,
  preload hint, explicit width/height attributes (prevents CLS).
- Custom font (display): render-blocking. Recommend: font-display: swap in motion token
  or system font fallback for LCP paint, progressive font enhancement after.

CLS Risk: MEDIUM
- No aspect ratio specified for hero → layout shift on image load.
  Recommend: aspect-ratio CSS or explicit height in wireframe spec.

Remediation tokens:
  motion.duration.instant: 0ms  ← use for above-fold transitions
  motion.easing.linear       ← use for skeleton → content swap
```

### Evaluate animation tokens

```
@performance-aware-design evaluate tokens/semantic/motion.tokens.json
for INP compliance
```

### Font loading strategy

```
@performance-aware-design recommend a font loading strategy for the type scale
defined in tokens/core/typography.tokens.json
```

### Score a design spec

```
@performance-aware-design score the wireframe at docs/wireframes/homepage.spec.md
against Core Web Vitals budgets
```

## Assessment artifact roles

These suggested downstream artifact names are not bundled template files.
Author them from the metric table, scenarios, and schema below.

| Template | Purpose |
|---|---|
| `performance-assessment-template.md` | Per-page performance impact assessment with metric scores |
| `font-loading-strategy-template.md` | Font loading decision tree with token recommendations |
| `image-strategy-template.md` | Image format, sizing, and loading strategy per component |

## Output Schema

```yaml
discriminator: audit-report
scope: page | component | token-set
lcp_risk: low | medium | high
cls_risk: low | medium | high
inp_risk: low | medium | high
recommendations: [string]
token_changes: [{token: string, current: string, recommended: string}]
gate_passed: boolean
```
