# Spec 04 — Instruction Layers

> Normative spec for `instructions/`. Implements root SPEC §7. Mirrors basecoat's
> numeric layering with a `sheen-` prefix.

## 1. File naming

```
instructions/sheen-<NN>-<layer>-<topic>.instructions.md
```

- `<NN>` is the two-digit layer band (below).
- `<layer>` is the band's short name; `<topic>` is kebab-case.
- Example: `sheen-30-components-states.instructions.md`.

## 2. Layer bands

| Band | Layer | Purpose | Example topic |
|---|---|---|---|
| 10 | core | Always-on design principles & values | `design-principles`, `brand-voice` |
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
description: "Always-on guidance for <topic>."
applyTo: "**/*"            # or a glob scope, e.g. "**/*.css", "**/*.tokens.json"
metadata:
  band: <NN>
  layer: <layer>
---
```

- `applyTo` scopes the instruction. Broad principles use `**/*`; technical rules
  scope to relevant file globs (CSS, token JSON, markup, locale files).

## 4. Precedence

- Within a request, all matching instructions apply.
- On conflict, **more specific scope wins** (narrow glob > `**/*`), then **higher
  band wins** (80 > 10). Instructions SHOULD be written to avoid conflict.
- Instructions are guidance, not executable checks; hard enforcement lives in
  `checks.json` (spec 05).

## 5. Instruction vs. skill

Use an **instruction** for always-on, ambient rules (naming, principles,
constraints). Use a **skill** (spec 02) for an invokable, multi-step workflow.
When unsure, prefer an instruction — it is cheaper and composes automatically.

## 6. Core set (v1 target)

`sheen-10-core-design-principles`, `sheen-10-core-accessibility`,
`sheen-20-tokens-naming`, `sheen-30-components-states`,
`sheen-40-web-usability`, `sheen-50-brand-voice`, `sheen-60-ia-navigation`,
`sheen-70-taxonomy-ontology`, `sheen-80-content-multilingual`,
`sheen-90-standards-conformance`.
