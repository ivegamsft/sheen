---
name: design-to-code
compatibility: [github-copilot-cli]
description: "Use when generating component code scaffolds from design specs, tokens, or Figma exports. USE FOR: scaffold a React/Vue/Web Component from a component spec, generate token-bound CSS/SCSS from a design spec, convert a wireframe spec to a typed component interface, produce Storybook story shells from component anatomy. DO NOT USE FOR: business logic implementation, backend API design, infrastructure provisioning."
category: development
metadata:
  category: development
  maturity: stable
  audience:
    - developer
    - designer
allowed-tools: []
---
# Design-to-Code Skill

Bridge the gap between design specs and implementation by generating component scaffolds, token bindings, and typed interfaces from `ux` skill outputs.

## Closes

GitHub issue #59 — `feat(skill): design-to-code — component code generation from spec (React/Vue/Web Components)`

## Workflow

```
component-spec (ux skill) → design-to-code → scaffold output
                          ↘ token bindings (build-tokens.ps1)
                          ↘ Storybook story shell
                          ↘ TypeScript interface
```

## Templates in This Skill

| Template | Purpose |
|---|---|
| `react-component-template.md` | React functional component + CSS Modules scaffold |
| `vue-component-template.md` | Vue 3 SFC scaffold with token bindings |
| `web-component-template.md` | Vanilla Custom Element scaffold |
| `storybook-story-template.md` | Storybook CSF3 story shell with all variants |
| `component-interface-template.md` | TypeScript props interface derived from component spec |

## Sample Prompts

### Generate a React component from spec

```
@design-to-code scaffold a React component for the spec in docs/components/card.spec.md
using tokens from tokens/semantic/. Output to src/components/Card/.
```

**Agent flow:** `design-system-architect` → `design-to-code` → `frontend-dev`

**Output shape:**
- `src/components/Card/Card.tsx` — typed functional component
- `src/components/Card/Card.module.css` — token-bound CSS Module
- `src/components/Card/Card.stories.tsx` — Storybook CSF3 story
- `src/components/Card/index.ts` — barrel export

**Gate condition:** component renders without errors; token references resolve in `dist/tokens/`

### Generate a Vue SFC from wireframe

```
@design-to-code scaffold a Vue 3 SFC for the wireframe spec in docs/wireframes/modal.spec.md
```

### Generate TypeScript interface from component anatomy

```
@design-to-code generate a TypeScript props interface from the anatomy table
in docs/components/button.spec.md
```

## Output Schema

```yaml
discriminator: component-spec
files:
  - path: src/components/{Name}/{Name}.{ext}
    type: component
  - path: src/components/{Name}/{Name}.module.css
    type: styles
  - path: src/components/{Name}/{Name}.stories.{ext}
    type: storybook
  - path: src/components/{Name}/index.ts
    type: barrel
token_bindings:
  - semantic_token: string
    css_var: string
    value_at_build: string
```

## Agent Pairing

- Input from: `ux-designer` (component-spec), `design-system-architect` (token-spec)
- Output to: `frontend-dev` (implement logic), `design-reviewer` (visual QA)
- Close loop: `design-drift-detection` verifies generated code matches spec
