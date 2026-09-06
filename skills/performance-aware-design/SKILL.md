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

Evaluate typography, imagery, tokens, and motion against measurable performance budgets.

## Workflow
1. Scope the page, component, or token set; gather hero/image, font-loading, and animation decisions.
2. Read and apply the [performance contract](references/performance-contract.md): all good/needs-work/poor thresholds, design triggers, scenarios, artifact roles, and schema.
3. Assess LCP/CLS/INP risks; evaluate image sizing/loading/aspect ratios, font fallback/swap, and motion chains/token choices.
4. Recommend loading strategies and token changes, record evidence or estimates, and hand off budget and implementation work.

## Guardrails
- Good thresholds: LCP ≤2.5s, CLS ≤0.1, INP ≤200ms; retain the reference's FID comparison for legacy assessment.
- Distinguish estimated design risk from measured runtime compliance; do not claim an example's budget is a measurement.
- Preserve reduced-motion accessibility; no backend tuning, database optimization, or infrastructure scaling.

## Output
- Downstream page assessment, font-loading strategy, and per-component image strategy.
- Reference `audit-report` schema: scope, LCP/CLS/INP risks, recommendations, token/current/recommended changes, gate status.

## Delegates / pairs with
- Triggered by: `ux-designer` (before final wireframe), `design-reviewer` (pre-ship).
- Feeds: `design-system-architect` (token budgets), `frontend-dev` (implementation hints).
- Pairs: `accessibility-auditor` (reduced-motion token compliance).
