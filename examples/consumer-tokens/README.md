# Consumer Tokens Example

This is a lightweight vanilla consumer that demonstrates how a product repo can consume `basecoat-sheen` DTCG tokens and generate CSS custom properties.

It is intentionally self-contained:

- no committed `node_modules`
- no committed `dist` output
- no build dependencies beyond Node.js
- defaults to the repository's `..\..\tokens` folder when run inside this example

## Files

| File | Purpose |
| --- | --- |
| `package.json` | Defines local token build and preview scripts. |
| `scripts\build-tokens.mjs` | Reads DTCG JSON, resolves aliases, and emits theme-scoped CSS variables. |
| `src\index.html` | Minimal page that loads the generated token CSS. |
| `src\app.css` | App styles that consume semantic CSS variables. |

## Run locally

From this directory:

```powershell
npm install
npm run tokens:build -- --theme light
npm run tokens:build -- --theme dark
npm run dev
```

Open the printed local URL and toggle `data-theme` on the `<html>` element between `light` and `dark` in dev tools.

## Copying the pattern to a real consumer repo

1. Sync or copy sheen tokens into `tokens\` in the consumer repo.
2. Copy `scripts\build-tokens.mjs` and adapt the output path if needed.
3. Add scripts similar to:

```json
{
  "scripts": {
    "tokens:build": "node scripts/build-tokens.mjs --theme light",
    "tokens:build:dark": "node scripts/build-tokens.mjs --theme dark"
  }
}
```

4. Load `dist\tokens-light.css` before app CSS.
5. Run `pwsh -NoProfile -ExecutionPolicy Bypass -File scripts\validate-tokens.ps1 tokens` in CI before building artifacts.

## Theme output

The generated CSS is scoped by theme:

```css
:root,
[data-theme="light"] {
  --sheen-color-background: #ffffff;
  --sheen-color-foreground: #1f2328;
}
```

The application should consume semantic variables, not raw palette values:

```css
.card {
  color: var(--sheen-color-foreground);
  background: var(--sheen-color-surface);
}
```
