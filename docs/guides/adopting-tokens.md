# Adopting Tokens

Use this guide when a consuming product, documentation site, or design tool wants to adopt the `basecoat-sheen` DTCG token source under `tokens/` and generate platform-specific theme outputs. It complements the shorter [Token Build & CI Integration](token-build-ci.md), [Token Application Patterns](../quick-refs/token-application-patterns.md), and [Token-only pattern](../patterns/token-only.md) references.

## Adoption flow

1. **Pin and sync sheen assets** into the consumer repo with a stable release ref.
2. **Map existing styles to semantic roles** such as `color.background`, `color.foreground`, `color.primary`, and `type.body`.
3. **Resolve contrast and completeness gaps** before replacing production styles.
4. **Generate platform outputs from the DTCG source** instead of hand-maintaining CSS, Figma, or Storybook values.
5. **Validate every change in CI** so broken references, invalid JSON, and theme drift fail before release.

Avoid bypassing semantic roles with raw color stops. Core tokens are implementation primitives; product components should consume semantic or component-level aliases.

## Token pipeline at a glance

The repository keeps tokens in three tiers:

| Tier | Path | Purpose | Consumer guidance |
| --- | --- | --- | --- |
| Core | `tokens/core/*.tokens.json` | Literal primitives such as palette, spacing, radius, motion, elevation, materials, and type scale. | Do not theme directly from core values except inside build transforms. |
| Semantic | `tokens/semantic/*.tokens.json` | Stable roles and text styles that alias core tokens. | Use as the source of truth for product code and design tools. |
| Themes | `tokens/themes/*.tokens.json` | Light, dark, and high-contrast values that override semantic roles without adding new keys. | Select one theme per runtime surface; keep every semantic key covered. |

A typical build reads core + semantic + one theme, resolves `{token.path}` aliases, and emits the target artifact:

```text
tokens/core + tokens/semantic + tokens/themes/light.tokens.json
  -> validate schema, references, completeness, contrast
  -> resolve aliases
  -> emit CSS custom properties, Figma Tokens JSON, Storybook theme objects, or native assets
```

## Local theme/token build workflow

Run validation from the repository root before generating downstream artifacts:

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File scripts\validate-tokens.ps1 tokens
```

The validator checks DTCG JSON syntax, allowed `$type` values, tier discipline, semantic references, theme completeness, and WCAG contrast pairs. Metadata drift is checked separately:

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File scripts\build-metadata.ps1 -Check
```

Consumers usually add their own build transform. Keep it deterministic and make the theme explicit:

```powershell
npm run tokens:build -- --theme light
npm run tokens:build -- --theme dark
npm run tokens:build -- --theme high-contrast
```

The lightweight example at `examples\consumer-tokens` demonstrates this pattern with a dependency-free Node script that reads the DTCG source and writes CSS variables.

### Minimal resolver shape

```js
const core = loadTokens('tokens/core');
const semantic = loadTokens('tokens/semantic');
const theme = loadTokens('tokens/themes/light.tokens.json');
const merged = { ...core, ...semantic, ...theme };
const css = toCssVariables(resolveAliases(merged), '--sheen');
```

Prefer generated files such as `dist/tokens.css` or `src/generated/tokens.css` in consumers. Do not edit generated output by hand.

## Applying themes in products

### CSS custom properties

Generate semantic CSS variables and scope theme files with attributes or classes:

```css
:root,
[data-theme='light'] {
  --sheen-color-background: #ffffff;
  --sheen-color-foreground: #1f2328;
  --sheen-color-primary: #0969da;
  --sheen-color-on-primary: #ffffff;
  --sheen-type-body-font-size: 1rem;
}

[data-theme='dark'] {
  --sheen-color-background: #0d1117;
  --sheen-color-foreground: #f0f6fc;
}

.button {
  color: var(--sheen-color-on-primary);
  background: var(--sheen-color-primary);
  border-radius: var(--sheen-radius-md, 0.375rem);
}
```

Use component aliases in app styles if you need product-specific naming, but map them back to semantic variables:

```css
:root {
  --app-action-bg: var(--sheen-color-primary);
  --app-action-fg: var(--sheen-color-on-primary);
}
```

### Figma Tokens

For Figma, keep the same hierarchy:

1. Import core token sets as non-themed primitives.
2. Import semantic token sets as the designer-facing roles.
3. Import light/dark/high-contrast theme sets as theme overrides.
4. Publish semantic roles to libraries; avoid exposing raw palette stops as component decisions.

Example set naming:

```text
basecoat/core/color
basecoat/core/type
basecoat/semantic/color
basecoat/semantic/type
basecoat/themes/light
basecoat/themes/dark
basecoat/themes/high-contrast
```

When the plugin or a design-token service exports to code, preserve DTCG `$value` references so CI can still catch dangling aliases.

### Storybook theming

Use one decorator that switches the theme attribute and imports the generated CSS:

```ts
// .storybook/preview.ts
import '../src/generated/sheen-light.css';
import '../src/generated/sheen-dark.css';

export const globalTypes = {
  theme: {
    name: 'Theme',
    defaultValue: 'light',
    toolbar: { icon: 'circlehollow', items: ['light', 'dark', 'high-contrast'] },
  },
};

export const decorators = [
  (Story, context) => {
    document.documentElement.dataset.theme = context.globals.theme;
    return Story();
  },
];
```

For framework-specific providers, pass only resolved semantic values into the provider and keep raw token parsing in the build step.

## CI/CD integration

### GitHub Actions validation

This repository's `.github\workflows\ci.yml` includes a `tokens` job that:

- validates all token JSON with `jq`
- installs PowerShell when token files exist
- runs `pwsh -NonInteractive -File scripts\validate-tokens.ps1 tokens`

Consumers should copy the same gate or call the script after syncing tokens:

```yaml
name: Tokens
on: [pull_request]
jobs:
  tokens:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Install PowerShell
        run: |
          sudo apt-get update -qq
          sudo apt-get install -y -qq powershell
      - name: Validate sheen tokens
        run: pwsh -NonInteractive -File scripts/validate-tokens.ps1 tokens
      - name: Build theme outputs
        run: npm run tokens:build -- --theme light
```

Add the build output check that matches your repo policy: either commit generated artifacts and fail on drift, or treat generated CSS/Figma exports as release artifacts.

### Pre-commit hooks

Use a local hook for quick feedback before CI. Save this as `.git\hooks\pre-commit` and make it executable on platforms that require it:

```powershell
#!/usr/bin/env pwsh
pwsh -NoProfile -ExecutionPolicy Bypass -File scripts\validate-tokens.ps1 tokens
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
npm run tokens:build -- --theme light
```

If your team uses a hook manager, wire the same commands into `pre-commit`, Husky, Lefthook, or your existing task runner. Keep the hook fast; reserve full multi-platform artifact generation for CI.

### Changelog and release automation

Token changes affect consumers, so include them in release notes:

- **Major**: removing or renaming published semantic tokens, changing token meaning, changing the theme hierarchy, or altering build output contracts.
- **Minor**: adding new semantic tokens, new component aliases, or new themes without breaking existing keys.
- **Patch**: fixing values, descriptions, documentation, or generator bugs without changing public names.

Use `CHANGELOG.md` and `version.json` as the release source of truth. Automation can require a changelog entry when files under `tokens/` change:

```yaml
- name: Require token changelog note
  run: |
    git diff --name-only origin/main...HEAD | grep '^tokens/' >/dev/null || exit 0
    grep -qi 'token' CHANGELOG.md
```

Most teams implement this check with a changed-files action or repository policy bot, then tag releases with the same semver used by consumer `.sheen.yml` refs.

## Override and extension patterns

### Theme hierarchy

Use this precedence order:

```text
core primitives -> semantic roles -> theme overrides -> product/component aliases
```

Rules of thumb:

- Core tokens must remain literal and context-free.
- Semantic tokens define stable role names.
- Theme files may override values but must not introduce new semantic keys.
- Product aliases may narrow use (`button.primary.background`) but should reference semantic roles.

### Custom tokens

Add product-specific tokens in a namespaced file in the consumer repo, not directly in upstream sheen unless they are reusable across products:

```json
{
  "product": {
    "dashboard": {
      "kpi-positive": {
        "$type": "color",
        "$value": "{color.success}",
        "$description": "Positive KPI delta in dashboard cards."
      }
    }
  }
}
```

Keep custom tokens close to semantic names and document why they exist. If a custom token becomes broadly useful, promote it through normal contribution and changelog review.

### Extension points

- **Brand themes**: add `brand-a.tokens.json` and `brand-b.tokens.json` only after semantic coverage is complete.
- **Component tokens**: add aliases such as `component.button.background` when many components need the same semantic combination.
- **Platform transforms**: generate CSS, Tailwind, Figma, Storybook, Swift, Kotlin, or other outputs from the same DTCG source.
- **Accessibility gates**: extend contrast pairs in `scripts\validate-tokens.ps1` when new foreground/background roles become public.

## Example consumer repository

See `examples\consumer-tokens` for a minimal vanilla setup:

```powershell
cd examples\consumer-tokens
npm install
npm run tokens:build -- --theme light
npm run tokens:build -- --theme dark
npm run dev
```

The example contains:

- `package.json` with build and preview scripts
- `scripts\build-tokens.mjs` to read DTCG JSON and emit CSS custom properties
- `src\index.html` and `src\app.css` that consume generated variables
- `README.md` explaining how to copy the pattern into a real consumer repo

It intentionally does not commit `node_modules` or generated `dist` output.

## FAQ

### How should token versions be pinned?

Pin consumers to a release tag or immutable commit. Avoid floating `main` in production because raw token changes can alter generated CSS, Figma libraries, or Storybook snapshots without an explicit upgrade.

### What counts as backward compatible?

Adding tokens, adding a theme that covers all semantic keys, improving descriptions, and fixing invalid values are usually backward compatible. Removing, renaming, or repurposing a published semantic token is breaking and requires a major version.

### How do we migrate between versions?

Read the [Migration pattern](../patterns/migration.md), review `CHANGELOG.md`, update the `.sheen.yml` `ref`, regenerate outputs, and run visual/accessibility regression checks before release. For major upgrades, migrate through intermediate releases if the changelog recommends it.

### Can we keep old token names temporarily?

Yes. Keep deprecated aliases for at least one minor release when possible, mark them with `$deprecated: true` and a migration note, then remove them in the next major version. Document the removal in `CHANGELOG.md`.

### Should generated CSS be committed?

Either policy works. Libraries often commit generated artifacts so package consumers do not need the build toolchain. Apps often generate during CI and publish artifacts. In both cases, CI should detect drift between DTCG source and generated output.

### Can a product override high-contrast values?

Only if the replacement still passes the stricter high-contrast gate. Run `scripts\validate-tokens.ps1` after every override and test with real OS/browser high-contrast settings where possible.
