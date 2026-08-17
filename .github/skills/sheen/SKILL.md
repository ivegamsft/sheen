---
name: sheen
compatibility: [github-copilot-cli]
description: "Use when you need to discover the right Sheen design agent or route a request to the correct UX/design discipline. USE FOR: find the right Sheen agent, browse the design skill catalog, route a prompt to ux-designer or accessibility-auditor, discover which agent handles brand or token work, delegate a design task to the right pillar. DO NOT USE FOR: implementing product features, editing skill internals, engineering/infrastructure concerns (route those to basecoat)."
category: framework
metadata:
  category: framework
  domain: routing
  maturity: production
  audience:
    - designer
    - developer
    - maintainer
visibility: public
allowed-tools: []
---
# Sheen Router

The front door to the Sheen design-system framework. Routes requests to the right agent across
6 design pillars in two modes: **Discovery** (browse agents and skills) and **Delegation** (route directly).

## Quick Start

```text
/sheen                              → Full agent catalog by pillar
/sheen find "dark mode"             → Search skills by keyword
/sheen tokens design a dark-mode token schema   → Delegate to @design-system-architect
/sheen help ux-designer             → Detailed usage card for @ux-designer
```

## Reference Files

| File | Contents |
|------|----------|
| [`references/authoring.md`](references/authoring.md) | Discovery mode, delegation mode, examples |
| [`references/governance.md`](references/governance.md) | Pillar keyword routing table, vocabulary registry, governance rules |
| [`references/factory-patterns.md`](references/factory-patterns.md) | Multi-agent composition patterns (parallel audit, serial chain, token cascade) |

## Pillars & Agents

| Pillar | Keywords | Agent |
|--------|----------|-------|
| 🎨 Tokens & System | token, color, typography, theme, dark-mode, css | `@design-system-architect` |
| 🖼️ Brand | brand, logo, imagery, voice, tone, illustration | `@brand-steward` |
| 📐 Usability | wireframe, layout, navigation, responsive, journey | `@ux-designer` |
| ♿ Accessibility | a11y, wcag, aria, contrast, focus, keyboard | `@accessibility-auditor` |
| 🗂️ Information Architecture | ia, taxonomy, ontology, sitemap, navigation, content | `@information-architect` |
| ✅ Governance | review, critique, debate, craft, audit, tradeoff | `@design-reviewer` |

## Basecoat Integration

Cross-domain requests that arrive via `/basecoat ux`, `/basecoat design`, `/basecoat brand`,
or `/basecoat a11y` are delegated here. Sheen operates as a named delegate in the basecoat
router's governance table; engineering/security concerns route back to basecoat.
