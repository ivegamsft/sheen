# Prompt Guide — Sheen Agents, Skills & Intents

A practical cookbook for downstream users. Every agent, skill, and intent in sheen is
covered here with:

- **What it does** — one-line mandate
- **When to invoke** — trigger conditions
- **Sample prompt** — copy-paste ready
- **Flow** — what the agent/skill does step by step
- **Output** — what you get back

---

## How to invoke sheen

```text
/sheen <pillar-keyword> <your request>    ← delegate to the right agent
/sheen find "<term>"                      ← search by keyword
/sheen help <agent-name>                  ← usage card for one agent
/sheen                                    ← full catalog
```

Use the router disambiguation rules when a term is ambiguous (see
[ADR-002](../../decisions/adr-002-intent-disambiguation.md)):
`/sheen:debate` forces sheen routing; `/basecoat:rca` forces basecoat routing.

---

## Agent quick-reference

| Agent | Pillar | Invoke with | Page |
|-------|--------|-------------|------|
| `@design-system-architect` | 🎨 Tokens & System | `/sheen token`, `/sheen theme`, `/sheen css` | [Tokens & System](tokens-system.md) |
| `@brand-steward` | 🖼️ Brand | `/sheen brand`, `/sheen logo`, `/sheen voice` | [Brand](brand.md) |
| `@ux-designer` | 📐 Usability | `/sheen wireframe`, `/sheen layout`, `/sheen flow` | [Usability](usability.md) |
| `@accessibility-auditor` | ♿ Accessibility | `/sheen a11y`, `/sheen wcag`, `/sheen contrast` | [Accessibility](accessibility.md) |
| `@information-architect` | 🗂️ IA | `/sheen ia`, `/sheen taxonomy`, `/sheen ontology` | [Information Architecture](information-architecture.md) |
| `@design-reviewer` | ✅ Governance | `/sheen review`, `/sheen debate`, `/sheen audit` | [Governance](governance.md) |

---

## Intent index

All 46 intents mapped to their agent, skill, and trigger keywords.

| Intent | Keywords | Skill | Agent |
|--------|----------|-------|-------|
| `wireframe-a-flow` | wireframe, lo-fi, sketch, flow-diagram | wireframing | @ux-designer |
| `debate-design-options` | debate, tradeoff, adr, compare, options | design-debate | @design-reviewer |
| `audit-accessibility` | a11y, accessibility, wcag, aria | accessibility-audit | @accessibility-auditor |
| `design-token-schema` | token, tokens, semantic-token, alias | design-tokens | @design-system-architect |
| `color-system-design` | color, colour, palette, hue | color-system | @design-system-architect |
| `typography-scale` | typography, typeface, font, type-scale | typography | @design-system-architect |
| `theming` | theme, theming, dark-mode, light-mode, high-contrast | theming | @design-system-architect |
| `css-token-mapping` | css, css-variable, component-token | css-mapping | @design-system-architect |
| `motion-elevation-design` | motion, animation, elevation, shadow | motion-elevation | @design-system-architect |
| `font-mapping` | font-stack, font-mapping, web-font | font-mapping | @design-system-architect |
| `brand-identity-review` | brand, brand-identity, visual-identity | brand-identity | @brand-steward |
| `logo-usage-review` | logo, logotype, mark, logo-usage | logo-usage | @brand-steward |
| `imagery-illustration` | imagery, illustration, photography | imagery-illustration | @brand-steward |
| `brand-voice-tone` | voice, tone, microcopy, brand-voice | brand-voice-tone | @brand-steward |
| `iconography-review` | icon, iconography, pictogram | iconography | @brand-steward |
| `responsive-layout` | responsive, mobile, breakpoint, viewport | responsive-design | @ux-designer |
| `layout-grid-spacing` | layout, grid, spacing, density | layout-grid-spacing | @ux-designer |
| `navigation-design` | navigation, nav, menu, wayfinding | navigation-design | @ux-designer |
| `user-journey-mapping` | user-journey, journey-map, flow, user-flow | user-research | @ux-designer |
| `ux-writing` | ux-writing, label, cta, help-text, error-text | ux-writing | @ux-designer |
| `ui-states-interaction` | interaction, state, hover, focus, active | ui-states-interaction | @ux-designer |
| `landing-page-design` | landing-page, hero, above-fold | landing-page-design | @ux-designer |
| `web-usability-review` | usability, heuristic, web-usability | web-usability-review | @ux-designer |
| `color-contrast-check` | contrast, color-contrast, luminance | color-contrast-check | @accessibility-auditor |
| `keyboard-focus-audit` | keyboard, focus-ring, tab-order, screen-reader | accessibility-audit | @accessibility-auditor |
| `usability-mapping` | usability-mapping, usability-score, heuristic-check | usability-mapping | @accessibility-auditor |
| `ia-taxonomy-design` | taxonomy, classification, hierarchy, category | taxonomy | @information-architect |
| `ontology-design` | ontology, vocabulary, controlled-vocabulary | ontology | @information-architect |
| `sitemap-ia` | ia, information-architecture, sitemap | information-architecture | @information-architect |
| `content-hierarchy` | content-hierarchy, content-model, content-type | content-hierarchy | @information-architect |
| `multilingual-i18n` | multilingual, i18n, l10n, locale, translation | multilingual | @information-architect |
| `craft-critique` | critique, craft, polish, craft-bar | craft-quality | @design-reviewer |
| `design-audit` | audit, design-audit, system-audit | design-audit | @design-reviewer |
| `pattern-library-review` | pattern, pattern-library, component-pattern | pattern-library | @design-reviewer |
| `secure-ux-review` | secure-ux, privacy-ux, security-design | secure-ux | @design-reviewer |
| `visual-regression` | regression, visual-regression, snapshot | visual-regression | @design-reviewer |
| `style-guide-authoring` | style-guide, document-guidelines, component-spec-page | style-guide-authoring | @design-reviewer |
| `design-system-audit` | design-system-audit, system-health, ds-audit | design-system-audit | @design-reviewer |
| `component-spec` | component-spec, component-anatomy, spec | component-spec | @ux-designer |
| `design-handoff` | handoff, design-handoff, dev-handoff | design-handoff | @ux-designer |
| `design-exploration` | exploration, ideation, concepts | design-exploration | @ux-designer |
| `design-suggest` | suggest, recommend, design-suggest | design-suggest | @design-reviewer |
| `design-update` | update, revision, design-update | design-update | @design-reviewer |
| `design-bootstrap` | bootstrap, scaffold, kick-off | design-bootstrap | @design-system-architect |
| `accessibility-conformance` | conformance, section-508, en-301-549 | accessibility-audit | @accessibility-auditor |
| `i18n-framework-mapping` | i18n-framework, rtl, bidi, language-support | i18n-framework-mapping | @information-architect |

---

## Multi-agent factory patterns

For requests that span multiple pillars, use a factory pattern instead of a single agent.
Templates are in `.github/skills/sheen/references/factory-patterns.md`.

| Pattern | When | Agents |
|---------|------|--------|
| **Parallel Audit** | Pre-release full review | @accessibility-auditor + @ux-designer + @design-reviewer |
| **Serial Decision-Chain** | Decide → spec → validate | @design-reviewer → @ux-designer → @accessibility-auditor |
| **Token Cascade** | New theme / rebrand | @design-system-architect → @brand-steward + @ux-designer → @design-system-architect |
