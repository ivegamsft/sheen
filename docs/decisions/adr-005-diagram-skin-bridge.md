# ADR-005 — Diagram Skin Is Generated From DTCG Tokens (Bridge, Not a Second Style Guide)

| Field | Value |
|---|---|
| **Date** | 2026-08-30 |
| **Status** | Accepted |
| **Deciders** | sheen maintainers |
| **Supersedes** | — |
| **Superseded by** | — |

## Context

The audit that opened epic #110 (comparing this repo's token/brand system
against `cathrynlavery/diagram-design`) found that the reference project
defines its diagram colours as an **independent palette hand-picked for
diagrams**, disconnected from any product design-token system. That is a
reasonable choice for a single-purpose diagram tool, but it is the wrong
choice for basecoat-sheen: this repo's entire reason for being is that colour,
typography, and spacing are defined once as DTCG tokens
(`tokens/**/*.tokens.json`) and every consumer (components, themes,
docs-site) derives from that single source. If diagrams got their own
hand-picked palette, we would have shipped a second, competing style system
that could drift out of sync with the product brand (e.g., a brand
re-theme would update every component but silently leave old diagram colours
behind) and that a designer would need to maintain twice.

## Options Considered

### Option 1 — Independent diagram palette (reference-project style)
Diagrams ship their own hard-coded hex palette, chosen for print/on-diagram
legibility, unrelated to `tokens/semantic/color.tokens.json`.

- ✅ Simple, no adapter layer needed
- ❌ Second style system; diverges silently from brand re-themes
- ❌ Directly the failure mode the original audit (#108/#109) flagged

**Score: 2/10**

### Option 2 — Diagrams consume raw semantic tokens directly
Diagram markup references `color.background`, `color.accent`, etc. with no
intermediate mapping.

- ✅ No adapter to maintain
- ❌ Semantic tokens are named for UI roles (background, surface-raised,
  border), not diagram roles (paper, ink, rule, series.N) — diagram authors
  would need to know UI-token semantics to pick the right diagram colour,
  and a UI-token rename would break every diagram

**Score: 5/10**

### Option 3 — Skin generated from DTCG tokens via a role adapter *(chosen)*
A build step (`scripts/build-diagram-skins.ps1`, delivered under #116) maps
diagram-domain roles (`paper`, `ink`, `muted`, `accent`, `rule-solid`,
`series.1-8`, ...) to the existing semantic tokens, and emits a themed
`dist/diagram-skins/<theme>.json` per theme (light/dark/high-contrast) at
build time. Diagrams consume only the diagram-domain roles; the adapter is
the single place that knows how those roles map to semantic tokens.

- ✅ Single source of truth preserved — a brand/theme change to
  `tokens/semantic/color.tokens.json` propagates to diagrams automatically
  on next build, with zero diagram-side edits
- ✅ Diagram authors get a small, diagram-shaped vocabulary (paper/ink/rule/
  series.N) instead of needing to reverse-engineer UI semantic names
- ✅ The adapter is auditable and lintable in isolation (`lint-diagram-skins.ps1`,
  #118) — contrast/polarity guarantees are checked once, for every theme, at
  the adapter boundary, rather than per-diagram
- ❌ Adds one more generated-artifact layer (`dist/diagram-skins/`) to the
  build pipeline

**Score: 9/10**

## Decision

**Adopt Option 3.** The diagram skin is a *generated bridge* from DTCG
tokens — never a hand-maintained, independent diagram palette. Every diagram
colour must resolve to a `dist/diagram-skins/<theme>.json` role, and every
role in that file must resolve back to a `tokens/semantic/*` or
`tokens/core/*` entry (enforced transitively by `scripts/validate-tokens.ps1`
and `scripts/lint-diagram-skins.ps1`).

## Consequences

- **Positive:** Resolves the original #108/#109 audit finding directly —
  there is no second style system to drift.
- **Positive:** A brand re-theme (new `tokens/themes/*.tokens.json` values)
  automatically re-colours every diagram on next CI build; no diagram PR
  needed.
- **Risk:** If a future diagram role has no reasonable semantic-token
  mapping, the temptation to hand-pick a one-off hex reappears. Any such case
  must be justified in the adapter's header comment (the `accent-tint`
  computed-blend case in `build-diagram-skins.ps1` is the existing precedent:
  documented as an intentional, non-token derived value, not a silent
  exception).

## Related

- `scripts/build-diagram-skins.ps1` (#116)
- `scripts/lint-diagram-skins.ps1` (#118)
- `docs/foundations/diagram-skin-adapter.md`
- Epic #110, issues #112, #116, #118
