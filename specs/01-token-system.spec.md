# Spec 01 — Token System

> Normative spec for `tokens/`. Implements root SPEC §6. Confirmed decision D1
> (tokens are first-class & validated) and D4 (DTCG JSON, aligned with Material 3
> + Fluent 2).

## 1. Purpose

`tokens/` is the machine-readable source of truth for every visual style value in
sheen. Skills read, write, and audit against it; consumers sync it and build it
into their platform format. Hardcoded style values are a governance violation.

## 2. Format

- Files MUST be valid [W3C DTCG](https://www.w3.org/community/design-tokens/) JSON.
- Every token MUST use `$type`, `$value`, and SHOULD include `$description`.
- References use DTCG alias syntax: `"{color.core.blue.60}"`.
- `$type` values in scope: `color`, `dimension`, `fontFamily`, `fontWeight`,
  `duration`, `cubicBezier`, `number`, `shadow`, plus composite groups for
  `typography`, `elevation`, and `material`.

## 3. Tiers

Three tiers mirror the DTCG **global → alias** model shared by M3 and Fluent 2.

### 3.1 `core/` — global primitives (context-agnostic)

| File | Contents |
|---|---|
| `color.tokens.json` | Palette ramps (e.g. `neutral.0…100`, brand hues), fixed steps |
| `type.tokens.json` | Font families, weights, size ramp, line-heights, letter-spacing |
| `space.tokens.json` | Spacing scale (even increments; e.g. 4/8/12/16/24/32…) |
| `radius.tokens.json` | Shape/geometry: corner radii scale |
| `elevation.tokens.json` | Elevation levels → shadow definitions |
| `materials.tokens.json` | Translucency/backdrop surfaces (Mica/Acrylic-style: blur, opacity, tint) |
| `motion.tokens.json` | Durations (e.g. `fast`=150ms) and easing curves |

Core tokens MUST NOT reference other tokens (they are the leaves).

### 3.2 `semantic/` — alias role & state tokens

- Reference core only; convey **meaning**, not raw value.
- Role examples: `color.surface`, `color.on-surface`, `color.primary`,
  `color.on-primary`, `color.border`, `color.focus-ring`.
- **State tokens** are REQUIRED for interactive roles:
  `…-hover`, `…-pressed`, `…-selected`, `…-disabled`, `…-focus`.
- Semantic tokens MUST resolve transitively to a core value with no cycles.

### 3.3 `themes/` — semantic overrides

- One folder/file per theme: `light`, `dark`, `high-contrast`, and `<brand>`.
- A theme overrides semantic token `$value`s only; it MUST NOT introduce new
  semantic keys absent from the base semantic tier.
- **Completeness**: every semantic token MUST resolve in every theme.

## 4. Cross-platform build

- `scripts/validate-tokens` validates; a build step (Style Dictionary or
  equivalent) transforms DTCG source into outputs: CSS custom properties, JS/TS
  ESM, and optional native formats.
- Build output is generated, not hand-edited, and MUST be reproducible in CI.
- Goal: single source of truth across web and app surfaces (Fluent 2 parity).

## 5. Naming

- Token paths are lowercase dot/segment kebab: `color.on-surface-hover`.
- Names MUST match the vocabulary in `.lexicon.md`; unknown segments fail lint.
- Core palette steps use numeric stops (`0`–`100`); semantic tokens never expose
  raw stops in their name.

## 6. Validation (see also spec 05)

`checks.json` → `scripts/validate-tokens` MUST enforce:

1. **Schema** — valid DTCG; all `$type` in the allowed set.
2. **References** — every alias resolves; no dangling refs; no cycles.
3. **Naming** — segments conform to `.lexicon.md`.
4. **Accessibility** — semantic foreground/background pairs meet WCAG 2.2:
   AA (4.5:1 text / 3:1 large & non-text) for `light`/`dark`; the
   `high-contrast` theme meets its stricter target (≥ 7:1 where applicable).
5. **Theme completeness** — every semantic token resolves in every theme,
   including all state variants.
6. **Tier discipline** — core has no refs; themes add no new keys.

Any failure is a hard CI error (not advisory), because downstream skills depend on
token integrity.

## 7. Skills that touch tokens

- Read/write: `design-tokens`, `color-system`, `typography`, `theming`,
  `motion-elevation`, `iconography`.
- Audit/verify: `color-contrast-check`, `design-system-audit`, `design-audit`.
- Reverse-map into tokens: `css-mapping`, `font-mapping`.

## 8. Versioning

- Token changes follow semver in `version.json`.
- Renaming or removing a published semantic token is **breaking** (major).
- Adding a token or theme is minor; changing a raw core value is minor unless it
  fails a consumer contrast contract, in which case treat as major.
