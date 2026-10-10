# Diagram Anti-Slop Rules (#115)

Enforceable, rule-ID'd checks for code/documentation diagrams (ported from
cathrynlavery/diagram-design's editorial anti-slop guidance), run via
`scripts/audit-diagram-slop.ps1 -SvgPath <file> -Theme <light|dark|high-contrast>`.
Every violation is reported with its rule ID so it drops directly into the
audit backlog as a single, unambiguous finding — never a vague "polish" note.

Run commands from a sheen source checkout, not from the synced skill folder.
Source tools: [slop audit](https://github.com/ivegamsft/sheen/blob/main/scripts/audit-diagram-slop.ps1)
and [geometry lint](https://github.com/ivegamsft/sheen/blob/main/scripts/lint-diagram-geometry.ps1).
`dist/diagram-skins/<theme>.json` is generated there, not bundled here.

| Rule ID | Checks | Auto-fail threshold |
|---|---|---|
| `DENSITY` | Node count | Target ~4/10; **>9 nodes** auto-fails — split into smaller diagrams or a drill-down hierarchy |
| `SHADOW` | Drop-shadow/blur filters | Any use — sheen diagrams are flat, borders only |
| `RADIUS` | `<rect>` corner radius | **>10px** (default max; 6-10px or none is the target) |
| `ACCENT-BUDGET` | Elements using `accent`/`accent-tint` | **>2** elements — accent is for 1-2 focal points, not decoration |
| `STRAY-HEX` | Fill/stroke colours vs. the resolved theme skin | Any hex not present in `dist/diagram-skins/<theme>.json` — catches neon and one-off hand-picked colours alike |
| `MONO-FONT` | Font-family across all text | All-monospace with no hierarchy (unless the diagram is intentionally all-code) |
| `SLANT`, `SHARED-ATTACH`, `OVERLAP-PATH`, `LABEL-UNMASKED`, `CLIPPED-LABEL`, `TRANSIT-BEHIND` | The six connector rules | Auto-fail — delegated to `scripts/lint-diagram-geometry.ps1` (#118) |

Source fixtures
[`clean-sample.svg`](https://github.com/ivegamsft/sheen/blob/main/tests/fixtures/diagrams/clean-sample.svg)
and [`broken-sample.svg`](https://github.com/ivegamsft/sheen/blob/main/tests/fixtures/diagrams/broken-sample.svg)
are asserted in CI to pass and fail (respectively) so the audit's own
effectiveness stays verified alongside its presence.
