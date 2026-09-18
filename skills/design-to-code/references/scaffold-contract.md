# Scaffold and Token-Binding Contract (#59)

Read before generating scaffolds. Apply the file/token schema and render gate;
scenarios cover React, Vue, and typed interfaces. All example source/spec/output
paths are downstream project paths, not files bundled with this skill.

## Generation flow

```
component-spec (ux skill) → design-to-code → scaffold output
                          ↘ token bindings (build-tokens.ps1)
                          ↘ Storybook story shell
                          ↘ TypeScript interface
```

## Scaffold artifact roles

These suggested downstream artifact names are not bundled template files.
Use the role descriptions, file layout, and schema to author the scaffolds.

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

## Build tooling

`build-tokens.ps1` refers to sheen's
[token builder](https://github.com/ivegamsft/sheen/blob/main/scripts/build-tokens.ps1).
Run the builder from a sheen source checkout or use the downstream's supplied
token build pipeline; a synced skill folder alone does not bundle that script.
