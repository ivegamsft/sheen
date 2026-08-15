# Token Application Patterns

## CSS

```css
:root {
  --color-surface: var(--token-color-surface);
  --color-text: var(--token-color-text);
}
```

## Figma

- map core tokens to semantic roles first
- keep theme overrides at the semantic layer
- avoid hard-coding raw palette stops into production components

## Storybook

```ts
export const ThemedStory = () => <ThemeProvider theme="dark"><Button /></ThemeProvider>;
```

## Platform output

- generate platform-specific artifacts from the token source of truth
- keep CI failing on broken references
- treat theme completeness as a release gate, not a nice-to-have
