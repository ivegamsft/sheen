# Sheen Router — Usage & Authoring

## Usage Modes

### Discovery Mode

| Command | What It Does |
|---------|--------------|
| `/sheen` | Full categorized agent catalog by pillar |
| `/sheen tokens` | Show only Tokens & System agents and skills |
| `/sheen brand` | Show only Brand agents and skills |
| `/sheen help [agent-name]` | Detailed usage card for one agent |
| `/sheen find "[search term]"` | Fuzzy search across skill keywords and intents |

Discovery results are organized by design pillar:

**🎨 Tokens & System** — `@design-system-architect`
Skills: `design-tokens`, `css-mapping`, `color-system`, `typography`, `theming`, `motion-elevation`, `font-mapping`

**🖼️ Brand** — `@brand-steward`
Skills: `brand-identity`, `brand-voice-tone`, `logo-usage`, `imagery-illustration`, `iconography`

**📐 Usability** — `@ux-designer`
Skills: `wireframing`, `ui-states-interaction`, `responsive-design`, `layout-grid-spacing`, `web-usability-review`, `user-research`, `ux-writing`, `landing-page-design`, `navigation-design`

**♿ Accessibility** — `@accessibility-auditor`
Skills: `accessibility-audit`, `color-contrast-check`, `usability-mapping`

**🗂️ Information Architecture** — `@information-architect`
Skills: `information-architecture`, `taxonomy`, `ontology`, `content-hierarchy`, `multilingual`, `i18n-framework-mapping`

**✅ Governance** — `@design-reviewer`
Skills: `design-review`, `design-debate`, `craft-quality`, `design-audit`, `design-system-audit`, `pattern-library`, `secure-ux`, `visual-regression`, `style-guide-authoring`

**🛠️ Lifecycle** — *(multi-agent, see factory-patterns.md)*
Skills: `design-bootstrap`, `design-handoff`, `design-update`, `design-exploration`, `design-suggest`, `component-spec`

### Delegation Mode

When a pillar keyword and prompt are provided, the router delegates directly:

```text
/sheen tokens design a dark-mode token schema with semantic aliases
→ Delegates to @design-system-architect with prompt "design a dark-mode token schema with semantic aliases"

/sheen a11y run a WCAG 2.2 AA audit for the checkout flow
→ Delegates to @accessibility-auditor

/sheen review critique the onboarding wireframes for craft and usability
→ Delegates to @design-reviewer
```

## Delegation Instructions

1. **Match** the first token after `/sheen` against the pillar keyword routing table in `governance.md`.
2. **Ambiguous match** — show top 2–3 candidates and ask the user to pick.
3. **Load the agent** — open the matched agent's `.agent.md` file.
4. **Pass the prompt** — forward everything after the keyword to the loaded agent.
5. **No match** — fall back to the full discovery menu with a note; suggest `/sheen find "[term]"`.
6. **Cross-domain** — if the request has no design dimension, route back to `/basecoat`.

## Examples

```text
/sheen                              → Full pillar catalog
/sheen brand                        → Brand pillar agents and skills
/sheen help design-system-architect → Detailed usage card
/sheen find "motion"                → Finds motion-elevation skill → @design-system-architect
/sheen tokens audit token naming for the dark theme
/sheen ia design a taxonomy for a SaaS product navigation
/sheen wireframe lo-fi flows for onboarding
```
