# Spec 04 — Instruction Layers

> Normative spec for `instructions/`. Implements root SPEC §7. Mirrors basecoat's
> numeric layering with a `sheen-` prefix.

## 1. File naming

```text
instructions/sheen-<NN>-<layer>-<topic>.instructions.md
```

- `<NN>` is the two-digit layer band (below).
- `<layer>` is the band's short name; `<topic>` is kebab-case.
- Example: `sheen-30-components-states.instructions.md`.

## 2. Layer bands

| Band | Layer | Purpose | Example topic |
|---|---|---|---|
| 10 | core | Surface-scoped design principles & values | `design-principles`, `accessibility` |
| 20 | tokens | Token naming, tiers, theming rules | `tokens-naming` |
| 30 | components | Component anatomy, states, variants | `components-states` |
| 40 | web/usability | NN/g heuristics, responsive rules | `web-usability` |
| 50 | brand | Voice, logo, imagery constraints | `brand-voice` |
| 60 | information architecture | Structure, navigation patterns | `ia-navigation` |
| 70 | taxonomy/ontology | Controlled vocab, relationships | `taxonomy-ontology` |
| 80 | content/localization | Microcopy, i18n/l10n rules | `content-multilingual` |
| 90 | standards/conformance | Cross-cutting standards gates (WCAG/ARIA/ISO/OWASP) | `standards-conformance` |

Lower bands are more general and load first; higher bands are more specific and
may refine (never contradict) lower ones.

## 3. Frontmatter

```yaml
---
name: sheen-<NN>-<layer>-<topic>
compatibility: [github-copilot-cli]
description: "Path-scoped guidance for <topic>."
applyTo: "**/*.css,**/*.tsx" # comma-separated GitHub Copilot glob patterns
metadata:
  band: <NN>
  layer: <layer>
---
```

- `applyTo` scopes every instruction to its actionable design/UI surface.
- Universal `**` or `**/*` scopes are prohibited: sheen must add no instruction
  context to backend, infrastructure, or data files that have no design surface.
- Multiple patterns use GitHub Copilot's supported comma-separated syntax.
  Brace expansion is not part of the contract.
- Broad design principles cover frontend markup/styles/components, design docs,
  assets, and tokens. More specialized layers narrow further to components,
  navigation, catalog assets, or locale/content paths.

## 4. Precedence

- Within a request, all matching instructions apply.
- On conflict, **more specific scope wins**, then **higher band wins** (80 > 10).
  Instructions SHOULD be written to avoid conflict.
- Instructions are guidance, not executable checks; hard enforcement lives in
  `checks.json` (spec 05).

## 5. Instruction vs. skill

Use an **instruction** for automatically applied, path-scoped ambient rules
(naming, principles, constraints). Use a **skill** (spec 02) for an invokable,
multi-step workflow or a full audit. When unsure, prefer the narrowest
instruction scope that covers the files where the guidance is actionable.

## 6. Core set (v1 target)

`sheen-10-core-design-principles`, `sheen-10-core-accessibility`,
`sheen-20-tokens-naming`, `sheen-30-components-states`,
`sheen-40-web-usability`, `sheen-50-brand-voice`, `sheen-60-ia-navigation`,
`sheen-70-taxonomy-ontology`, `sheen-80-content-multilingual`,
`sheen-90-standards-conformance`.
