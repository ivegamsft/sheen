# Diagram Semantic-Role Adapter

Part of [epic #110](https://github.com/IBuySpy-Shared/basecoat-sheen/issues/110)
(Position C — "bridge, don't fork"). Resolves diagram-design semantic roles
*from* `tokens/themes/*` at build time, so documentation/code diagrams (the
renderer landing in #113) never hard-code hex and automatically follow theme
switches (light / dark / high-contrast).

## Why a separate role set

Diagram tooling (Mermaid, drawio-style renderers, hand-rolled SVG) commonly
uses a compact "skin" vocabulary — `paper`, `ink`, `accent`, `rule`, etc. —
rather than the UI-oriented semantic names (`background`, `foreground`,
`accent`, `border`) already defined in `tokens/semantic/color.tokens.json`.
Rather than defining a second, parallel colour system (a fork), the adapter
is a thin build step that **maps one vocabulary onto the other**. There is
never a second source of truth for colour.

## Build

```pwsh
pwsh scripts/build-diagram-skins.ps1
```

Reads `tokens/` (core → semantic → themes) and emits, per theme, into
`dist/diagram-skins/` (git-ignored, rebuilt in CI — same convention as
`dist/tokens/` from `scripts/build-tokens.ps1`):

- `<theme>.json` — flat role → hex map, plus an 8-colour `series` array
- `skins.json` — all themes combined, keyed by theme name

## Role map

| Diagram role | Semantic token | Notes |
|---|---|---|
| `paper` | `color.background` | Canvas backdrop |
| `paper-2` | `color.surface-raised` | Panel / swimlane backdrop |
| `ink` | `color.foreground` | Primary text/line colour |
| `muted` | `color.muted` | Secondary text / de-emphasised nodes |
| `soft` | `color.border-muted` | Subtle divider / faint gridline |
| `rule` | `color.border-muted` | Default divider (alias of `soft`, kept distinct for diagram-design parity) |
| `rule-solid` | `color.muted` | Stronger divider / swimlane edge — `color.border` fails the 3:1 non-text floor in this token set, so this role uses `muted` instead (enforced by `scripts/lint-diagram-skins.ps1`, #118) |
| `accent` | `color.accent` | Emphasis / active-path colour |
| `accent-tint` | *derived* | Accent blended 25% into `paper`. Computed at build time (not a token) because no `accent-subtle` semantic token exists yet. |
| `link` | `color.link` | Cross-reference / edge-to-doc links |
| `series.1`–`series.8` | `color.data.series.1`–`8` | Per-lane / per-actor categorical colour (see #112) |

## Guarantees

- Every value in `dist/diagram-skins/*.json` traces to a token in `tokens/`
  — the only exception is `accent-tint`, which is a deterministic blend of
  two token values, never a hand-picked hex.
- Adding a semantic role to the map with no matching token fails the build
  loudly (`Theme '<name>' is missing semantic token '<key>'`), so drift
  between the role map and `tokens/semantic/color.tokens.json` cannot ship
  silently.
- CI (`.github/workflows/ci.yml`, `tokens` job) runs this build on every
  push touching `tokens/**/*.tokens.json`, alongside `build-tokens.ps1`.

## Lints (#118)

Two CI-wired lint scripts guard the adapter output and the renderer's SVG
conventions:

- `scripts/lint-diagram-skins.ps1` — runs after `build-diagram-skins.ps1`;
  checks every role resolves to a well-formed hex, that light/dark/
  high-contrast polarity holds (paper/ink inversion + the theme's
  accessibility contrast floor), and that `accent`, `rule-solid`, and every
  `series.N` clear the 3:1 non-text contrast floor against `paper`.
- `scripts/lint-diagram-geometry.ps1` — a static heuristic lint over a single
  SVG file's connector/label markup, covering the mechanically-checkable
  connector rules from #115's anti-slop list (`SLANT`, `SHARED-ATTACH`,
  `OVERLAP-PATH`, `LABEL-UNMASKED`, `CLIPPED-LABEL`, `TRANSIT-BEHIND`).
  `tests/fixtures/diagrams/baseline.svg` and `broken.svg` are asserted in CI
  to pass and fail (respectively) so the lint's own effectiveness is
  continuously verified, not just its presence.

## Icons (#111)

Node-type annotations (e.g. a person icon on an org-chart node, a
shield-lock icon on a DP security-matrix cell) are supplied by a small,
curated vendored icon subset — never a bespoke or hand-picked-hex icon set,
for the same "bridge, don't fork" reason the colour skin exists.

```pwsh
pwsh scripts/build-icons.ps1
```

Reads the vendored [Tabler Icons](https://github.com/tabler/tabler-icons)
(MIT) subset in `vendor/tabler-icons/icons/outline/` and emits, into
`dist/icons/` (git-ignored, rebuilt in CI):

- `<name>.svg` — normalized icon markup (24×24, `stroke="currentColor"`)
- `manifest.json` — `{ name, file, usage, sourceCommit }` per icon

Every vendored icon uses `stroke="currentColor"`, so it inherits its colour
from the diagram-skin adapter above via CSS `color` — icons never carry a
hard-coded hex. See the generated
[Diagram Icon Gallery](icon-gallery.md) for previews, and
[`vendor/tabler-icons/VENDOR.md`](https://github.com/IBuySpy-Shared/basecoat-sheen/blob/main/vendor/tabler-icons/VENDOR.md)
for the full provenance and per-diagram-type mapping. Attribution is tracked
in [`THIRD_PARTY_LICENSES.md`](https://github.com/IBuySpy-Shared/basecoat-sheen/blob/main/THIRD_PARTY_LICENSES.md).

## Renderer (#113)

`scripts/render-diagram.ps1` (dot-sourcing `scripts/render-diagram-types.ps1`)
is the consumer of everything above: it loads a `dist/diagram-skins/<theme>.json`
skin and `dist/icons/manifest.json`, and renders one of the 16 diagram types
kept in scope by [ADR-006](../decisions/adr-006-diagram-scope.md) into a
self-contained, static, accessible HTML+SVG file — no Mermaid, no CDN fonts,
no runtime dependencies, no motion (ADR-003).

```pwsh
pwsh scripts/render-diagram.ps1 -Type bar -SpecPath spec.json -OutPath out.html -Theme light
```

Full type list, spec schemas, and runnable sample specs are documented in
[`skills/documentation-diagram/SKILL.md`](https://github.com/IBuySpy-Shared/basecoat-sheen/blob/main/skills/documentation-diagram/SKILL.md).
Every rendered diagram is validated in CI against
`lint-diagram-geometry.ps1` and `audit-diagram-slop.ps1` above — the
renderer's output must pass both, unmodified, for every sample spec.

