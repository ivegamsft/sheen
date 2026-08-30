---
name: design-audit
compatibility: [github-copilot-cli]
description: "Top-level design assessment for an existing repo or product. USE FOR: repo-wide design audits, prioritizing UX/design debt, generating a remediation backlog from evidence. DO NOT USE FOR: editing only token files in isolation, greenfield system bootstrap from zero."
category: lifecycle
metadata:
  category: lifecycle
  maturity: stable
  audience: [designer, developer]
  pillar: lifecycle
allowed-tools: []
---
# Design Audit

Run a full-repo design governance audit and produce a prioritized backlog.

## Workflow
1. Inventory scope: surfaces, platforms, and user-critical journeys.
2. Run mapping passes (styles, typography, i18n, usability coverage) and collect gaps.
3. Evaluate against sheen standards: tokens, accessibility, usability, component coherence.
4. Severity-rank findings by user impact, risk, and implementation effort.
5. Convert findings into an actionable, ordered remediation backlog.

## Guardrails
- Do not rewrite product code as part of the audit pass.
- Do not claim compliance without concrete evidence per finding.
- Do not collapse separate issues into vague "polish" recommendations.

## Output
- Consolidated audit report with severity, rationale, and affected surfaces.
- Prioritized remediation backlog (quick wins, medium-term, structural fixes).

## Delegates / pairs with
- `css-mapping`, `font-mapping`, `i18n-framework-mapping`, `usability-mapping`
- `design-system-audit`, `accessibility-audit`, `web-usability-review`

## Diagram Anti-Slop Rules (#115)

Enforceable, rule-ID'd checks for code/documentation diagrams (ported from
cathrynlavery/diagram-design's editorial anti-slop guidance), run via
`scripts/audit-diagram-slop.ps1 -SvgPath <file> -Theme <light|dark|high-contrast>`.
Every violation is reported with its rule ID so it drops directly into the
audit backlog as a single, unambiguous finding — never a vague "polish" note.

| Rule ID | Checks | Auto-fail threshold |
|---|---|---|
| `DENSITY` | Node count | Target ~4/10; **>9 nodes** auto-fails — split into smaller diagrams or a drill-down hierarchy |
| `SHADOW` | Drop-shadow/blur filters | Any use — sheen diagrams are flat, borders only |
| `RADIUS` | `<rect>` corner radius | **>10px** (default max; 6-10px or none is the target) |
| `ACCENT-BUDGET` | Elements using `accent`/`accent-tint` | **>2** elements — accent is for 1-2 focal points, not decoration |
| `STRAY-HEX` | Fill/stroke colours vs. the resolved theme skin | Any hex not present in `dist/diagram-skins/<theme>.json` — catches neon and one-off hand-picked colours alike |
| `MONO-FONT` | Font-family across all text | All-monospace with no hierarchy (unless the diagram is intentionally all-code) |
| `SLANT`, `SHARED-ATTACH`, `OVERLAP-PATH`, `LABEL-UNMASKED`, `CLIPPED-LABEL`, `TRANSIT-BEHIND` | The six connector rules | Auto-fail — delegated to `scripts/lint-diagram-geometry.ps1` (#118) |

`tests/fixtures/diagrams/clean-sample.svg` and `broken-sample.svg` are
asserted in CI to pass and fail (respectively) so the audit's own
effectiveness stays verified alongside its presence.

