# Prompt Guide — 🎨 Tokens & System

**Agent:** `@design-system-architect`  
**Pillar:** Tokens & System  
**Invoke:** `/sheen token`, `/sheen theme`, `/sheen css`, `/sheen color`, `/sheen typography`, `/sheen motion`, `/sheen font`, `/sheen bootstrap`

The `design-system-architect` owns the entire token layer: primitives, semantic aliases,
component tokens, theming, CSS output, typography scale, motion, elevation, and font stacks.
It composes `design-tokens`, `theming`, `component-spec`, and `design-system-audit`.

---

## Agent-level prompts

### Bootstrap a new design system

```
/sheen bootstrap
Scaffold a complete design system for a SaaS analytics product.
Stack: React + Tailwind. We need light, dark, and high-contrast themes.
Include: primitive palette, semantic token layer, component tokens for
button/input/card/nav, and a CSS custom-property output ready for engineering.
```

**Flow:**
1. Clarify product context, brand palette seed, and target themes.
2. Run `design-tokens` — define primitive → semantic → component token tiers.
3. Run `theming` — generate light, dark, high-contrast theme overrides.
4. Run `component-spec` — map component tokens to anatomy (button states, input variants).
5. Run `css-mapping` — emit `--ds-*` CSS custom properties file.
6. Return: token JSON schema + CSS output + theme diff table.

**Output shape:**
```
📦 Token schema (JSON, DTCG format)
  ├── primitives/  color.json, scale.json, radius.json
  ├── semantic/    surface.json, text.json, interactive.json
  └── component/   button.json, input.json, card.json, nav.json

🎨 Theme outputs
  ├── light.tokens.json
  ├── dark.tokens.json
  └── high-contrast.tokens.json

📄 CSS output
  └── tokens.css  (--ds-color-surface-default, --ds-text-primary, …)

📋 Summary
  ├── Token count by tier
  ├── Theme coverage matrix
  └── Open gaps / TODOs
```

---

## Skill-by-skill reference

### `design-tokens` — Token schema design

**Intent:** `design-token-schema`  
**Keywords:** token, tokens, semantic-token, alias

**When to use:** You need to design or audit a token architecture — primitive palettes,
semantic roles, or component aliases. Use when starting a new system, adding a tier,
or refactoring token naming.

**Sample prompts:**

```
/sheen token
Design a semantic token layer for a fintech app.
Primitives are already defined. Map them to: surface (page, card, overlay),
text (primary, secondary, disabled, inverse), border, and interactive (default,
hover, active, disabled) roles. Output a JSON schema with DTCG $type annotations.
```

```
/sheen token
Audit the existing token JSON in tokens/semantic/ and flag any:
- missing semantic roles for interactive states
- tokens that reference primitives not in tokens/core/
- naming violations against the sheen-20-tokens-naming convention
```

**Flow:**
1. Ingest existing tokens or brief.
2. Map primitive → semantic → component tiers.
3. Flag gaps and naming violations.
4. Output annotated JSON schema with `$value`, `$type`, `$description`.

**Output:** Annotated JSON token schema · Gap report table · Naming violation list

---

### `color-system` — Color palette and semantic mapping

**Intent:** `color-system-design`  
**Keywords:** color, colour, palette, hue

**Sample prompt:**

```
/sheen color
Build a contrast-safe 10-step neutral palette and a 5-step accent palette
for a healthcare brand (primary: #005EB8). Map to semantic roles: surface,
text-on-surface, border, interactive. Flag any WCAG AA failures.
```

**Flow:**
1. Generate palette steps using perceptual lightness (OKLCH or HSL).
2. Run contrast check for all text/background pairings.
3. Map passing hues to semantic roles.
4. Flag failures with suggested replacements.

**Output:** Palette swatch table with hex + OKLCH · Contrast matrix · Semantic mapping · Failure report

---

### `typography` — Type scale and font pairing

**Intent:** `typography-scale`  
**Keywords:** typography, typeface, font, type-scale

**Sample prompt:**

```
/sheen typography
Define a modular type scale (ratio 1.25) for a content-heavy editorial product.
Base size 16px. Produce: display, h1–h4, body-lg, body, body-sm, caption, overline.
Map to semantic token names and include line-height and letter-spacing values.
```

**Flow:**
1. Compute scale steps from base size × ratio.
2. Apply optical adjustments for large and small ends.
3. Add line-height and letter-spacing per step.
4. Map to semantic names and output token JSON.

**Output:** Type scale table (px, rem, lh, ls) · Token JSON · Usage guidance per step

---

### `theming` — Theme generation and override design

**Intent:** `theming`  
**Keywords:** theme, theming, dark-mode, light-mode, high-contrast

**Sample prompt:**

```
/sheen theme
Add a dark-mode theme to our existing light token set.
We use CSS custom properties. For each semantic surface, text, border, and
interactive token: provide the dark-mode value, flag any pairs that fail
WCAG AA contrast in dark mode, and suggest corrections.
```

**Flow:**
1. Ingest light-mode token set.
2. Map semantic roles to dark-mode values (invert lightness, preserve hue).
3. Run contrast check across all text/surface pairings in dark mode.
4. Flag failures → suggest corrected values.
5. Emit dark.tokens.json and a CSS override block.

**Output:** Dark token JSON · Contrast failure table · CSS `@media (prefers-color-scheme: dark)` block

---

### `css-mapping` — CSS custom property output

**Intent:** `css-token-mapping`  
**Keywords:** css, css-variable, component-token

**Sample prompt:**

```
/sheen css
Convert our token JSON (tokens/semantic/ and tokens/themes/) into CSS custom
properties using the --ds-* namespace. Group by tier. Include :root for light
mode and [data-theme="dark"] override block. Skip deprecated tokens.
```

**Flow:**
1. Flatten token tree into `--ds-<tier>-<role>-<variant>` names.
2. Emit `:root { }` block for default theme.
3. Emit `[data-theme="dark"] { }` override block.
4. Flag any token referenced by components but absent from the CSS output.

**Output:** `tokens.css` file · Theme override block · Missing-reference report

---

### `motion-elevation` — Motion and elevation system

**Intent:** `motion-elevation-design`  
**Keywords:** motion, animation, elevation, shadow

**Sample prompt:**

```
/sheen motion
Design a motion system for a productivity app. Define: duration scale
(instant/fast/base/slow/deliberate), easing curves (enter/exit/standard),
and an elevation scale (0–5) with corresponding box-shadow values.
Map everything to design tokens.
```

**Flow:**
1. Define duration scale (ms values + semantic names).
2. Define easing curves (cubic-bezier) per motion type.
3. Define elevation steps with shadow recipe (y-offset, blur, spread, opacity).
4. Map to token JSON.

**Output:** Motion token JSON · Elevation token JSON · CSS animation utility classes · Usage guidelines

---

### `font-mapping` — Web font stack mapping

**Intent:** `font-mapping`  
**Keywords:** font-stack, font-mapping, web-font

**Sample prompt:**

```
/sheen font-mapping
Map our brand font (Inter for UI, Merriweather for editorial) to CSS font stacks
with system fallbacks. Define: font-family tokens for ui-sans, ui-serif, mono.
Include Google Fonts @import and font-display: swap. Flag any FOUT risk.
```

**Flow:**
1. Define primary + fallback stack for each font-family token.
2. Generate `@font-face` or `@import` declarations.
3. Apply `font-display: swap` and size-adjust for CLS mitigation.
4. Emit font-family token JSON.

**Output:** `@font-face` / `@import` block · font-family token JSON · FOUT risk notes

---

### `design-system-audit` — System health check

**Intent:** `design-system-audit`  
**Keywords:** design-system-audit, system-health, ds-audit

**Sample prompt:**

```
/sheen ds-audit
Audit our token system against sheen standards. Check:
- Are all semantic roles covered (surface/text/border/interactive)?
- Are component tokens consistent with semantic layer?
- Are all three themes (light/dark/high-contrast) complete?
- Are naming conventions following sheen-20-tokens-naming?
Return a scored health report.
```

**Flow:**
1. Load token inventory from `tokens/`.
2. Check tier completeness (primitive → semantic → component).
3. Run cross-theme coverage check.
4. Run naming convention validation.
5. Score each dimension and produce a health summary.

**Output:** Health scorecard (0–100 per dimension) · Gap list by severity · Remediation priorities
