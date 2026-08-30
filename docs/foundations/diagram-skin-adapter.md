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
| `rule-solid` | `color.border` | Stronger divider / swimlane edge |
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
