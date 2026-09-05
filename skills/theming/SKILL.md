---
name: theming
compatibility: [github-copilot-cli]
description: "Use when auditing or generating app-specific themes through comparable previews, scoped selection, and application readiness. USE FOR: theme candidate discovery and comparison, approved theme selection reuse, semantic overrides and theme completeness, custom theme creation and revision, theme application readiness and drift audit. DO NOT USE FOR: new semantic key creation, brand-only identity or voice guidance, reporting or chart generation, full accessibility audits."
category: foundation
metadata:
  category: foundation
  maturity: stable
  audience: [designer, developer]
  pillar: foundations
allowed-tools: []
---

# theming

Coordinate app-specific theme audit, selection, and authorized application.

## Workflow
1. Read the [lifecycle contract](references/lifecycle-contract.md); use the
   [record worksheet](templates/lifecycle-record.md) in the downstream's representation.
2. Inventory accepted brand/design-system decisions, observed usage, audience,
   surfaces, required modes/states, and capabilities. Audit without target changes.
3. Discover applicable candidates; reuse, extend, or justify creation. Compare
   exact revisions on identical representative content and conditions; label
   rendered/simulated/unrendered evidence and limitations.
4. Reuse an approved selection only after recorded applicability review; otherwise
   resolve material uncertainty and obtain policy-backed scoped selection.
5. Assess semantic mapping, fonts, capability, accessibility, impact, and recovery.
   Failed or unknown mandatory evidence blocks readiness.
6. Apply only with separate downstream change authorization; otherwise hand off.
   Review actual changed targets, record partial failure and recovery, preserve
   history, and reassess affected consumers on revision.

## Guardrails
- Accepted downstream brand and semantic keys remain authoritative; escalate conflicts.
- Selection is not readiness or permission to write/deploy. Explicit policy may
  delegate approval to an agent; do not add a universal human gate.
- Missing required visual evidence blocks readiness. Never silently install tools/fonts.
- No preset identities, reporting semantics, platform mandates, or unrelated UI changes.

## Output
- Linked candidate/comparison, selection/applicability, readiness/impact/recovery,
  application/review/history, and audit findings; keep unknowns explicit.
- Blueprint handoff references the selected revision, decisions, evidence, and
  affected catalog entries; it does not duplicate catalogs.

## Delegates / pairs with
- `brand-identity`, `design-exploration`, `design-debate`
- `typography`, `font-mapping`, `design-tokens`, `color-system`
- `color-contrast-check`, `accessibility-audit`, `design-review`, `visual-regression`
- `design-handoff`, `design-to-code`, `experience-blueprint`
- agent: `design-system-architect`
