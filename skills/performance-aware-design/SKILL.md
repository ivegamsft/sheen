---
name: performance-aware-design
compatibility: [github-copilot-cli]
description: "Use when evaluating design decisions for their impact on Core Web Vitals, font loading, image strategy, or animation performance. USE FOR: assess whether a design choice will degrade LCP or CLS, recommend a font loading strategy for the type scale, evaluate hero image design for LCP budget, flag animation token values that will cause jank, score a design against INP thresholds. DO NOT USE FOR: backend performance tuning, database query optimization, server infrastructure scaling."
category: development
metadata:
  category: development
  maturity: stable
  audience:
    - developer
    - designer
allowed-tools: []
---
# Performance-Aware Design Skill

Evaluate design decisions through the lens of Core Web Vitals — ensuring that token choices, typography, imagery, and animation are grounded in measurable performance budgets.

## Closes

GitHub issue #62 — `feat(skill): performance-aware-design — Core Web Vitals, font loading, image optimisation decisions`

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

## Templates in This Skill

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

## Agent Pairing

- Triggered by: `ux-designer` (before finalising wireframe), `design-reviewer` (pre-ship review)
- Feeds: `design-system-architect` (token budget changes), `frontend-dev` (implementation hints)
- Pairs with: `accessibility-auditor` (reduced motion token compliance)
