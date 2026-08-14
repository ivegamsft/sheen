---
name: sheen-20-tokens-naming
compatibility: [github-copilot-cli]
description: "Always-on naming and structure rules for DTCG design tokens in the sheen token system."
applyTo: "tokens/**"
metadata:
  band: 20
  layer: tokens
---

# Token Naming and Structure

Apply these rules when creating, editing, or reviewing any file under `tokens/`.
They implement the W3C DTCG format and the three-tier model defined in
`specs/01-token-system.spec.md` and `SPEC.md §6`.

## Three-tier model

| Tier | Directory | Role | Example |
|---|---|---|---|
| **Core** | `tokens/core/` | Raw global primitives (palette ramps, type scale, spacing, radius, elevation, materials, motion). Context-agnostic. | `color.blue.50`, `space.4` |
| **Semantic** | `tokens/semantic/` | Alias role tokens referencing core; named by *purpose*, not appearance. State tokens live here. | `color.surface`, `color.primary`, `color.on-primary` |
| **Theme** | `tokens/themes/` | Light / dark / high-contrast / brand overrides of semantic tokens. | `themes/dark/color.surface` |

## DTCG format (mandatory)

Every token must use the W3C Design Tokens Community Group (DTCG) JSON format:

```json
{
  "color": {
    "blue": {
      "50": {
        "$type": "color",
        "$value": "#e3f2fd",
        "$description": "Blue palette step 50 -- lightest."
      }
    }
  }
}
```

- `$type`: required. Valid types: `color`, `dimension`, `fontFamily`, `fontWeight`,
  `duration`, `cubicBezier`, `number`, `string`, `composite`.
- `$value`: required. Must be a literal for core tokens; an alias (`{token.path}`)
  for semantic and theme tokens.
- `$description`: required for every token. State the purpose, not the visual
  appearance.

## Naming rules

- **Format:** `category.scale-or-role[.variant]` in kebab-case. No underscores.
- **Core tokens** are named by *what they are* (palette position, scale step):
  `color.blue.50`, `space.4`, `radius.sm`, `motion.duration.fast`.
- **Semantic tokens** are named by *what they do* (purpose, role, state):
  `color.surface`, `color.primary`, `color.on-surface.hover`.
- **Theme tokens** mirror the semantic token path; the file context is the override.
- **State tokens** use a `.state` suffix: `color.primary.hover`, `color.primary.focus`,
  `color.primary.disabled`, `color.primary.pressed`, `color.primary.selected`.
- **Never** name a semantic token by its appearance (`color.blue-ish`,
  `color.dark-gray`). Appearance-named tokens belong in core only.

## Alias syntax

Semantic and theme tokens MUST reference core via the DTCG alias syntax:

```json
{ "$value": "{color.blue.50}" }
```

Cycles and unresolvable references are a `checks.json` hard error.

## Required categories (core)

`color` | `typography` | `space` | `radius` | `elevation` | `materials` | `motion`

Each category must exist in `tokens/core/` as a separate file or as a named
sub-object. Introducing a new top-level category requires a spec update in
`specs/01-token-system.spec.md`.

## Required themes

`light` | `dark` | `high-contrast` -- all three must resolve every semantic token.
A theme that leaves a semantic token undefined is a `checks.json` hard error.

## Review lens

Before finalizing any token change, ask:

- Is this a core, semantic, or theme token -- and is it in the right tier?
- Is the name based on purpose (semantic/theme) or appearance (core only)?
- Does every token have `$type`, `$value`, and `$description`?
- Do all semantic and theme tokens use alias syntax, not literal values?
- Does every semantic token resolve in all three themes?
- Are state variants present for interactive tokens?
