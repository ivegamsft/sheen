# Pattern 4: Token-Only

Pure design system governance, portable tokens, no AI agents, compliance-friendly.

## Profile

**Best fit:**
- Design system organization
- Compliance/governance teams (AI concerns)
- No Copilot or LLM budget
- Tokens are the only shared artifact
- Platform independence (web, mobile, print, native)

**Duration:** ongoing

**Team size:** dedicated design system team

**Why this pattern:**
- Machine-readable tokens, design system governance without AI
- Zero AI overhead (no agent costs, no model licensing)
- Portable (tokens work in Figma, CSS, Tailwind, native apps)
- Compliance-friendly (no LLM concerns, deterministic outputs)
- Easy to integrate with design-to-code workflows

---

## .sheen.yml config

Place this at your design system repo root.

```yaml
# Token-Only Mode — pure design system governance, no AI agents
source: https://github.com/IBuySpy-Shared/basecoat-sheen.git
ref: v0.5.0

# Exclude all skills/agents (tokens only)
skills: []
agents: []

# Include only token-focused instructions (guidance, not AI)
instructions:
  - sheen-20-tokens-naming
  - sheen-30-components-states
  - sheen-70-taxonomy-ontology
  - sheen-90-standards-conformance

# Include all themes for multi-platform support
themes: [light, dark, high-contrast]
```

---

## Workflow

### Phase 1: Token definition

1. **Design system team** edits `.tokens.json` files
   - Core tokens (palette, type scale, spacing, etc.)
   - Semantic tokens (roles, states, themes)
   - Component-specific tokens (optional)

2. **Validation:** Run `diagnose-sheen.ps1`
   - Checks token resolution (no broken references)
   - Validates schema (all required fields present)
   - Verifies naming conventions (sheen vocabulary)
   - Flags contrast issues (WCAG compliance)

### Phase 2: Materialization

3. **Build outputs:**
   - **CSS:** PostCSS/Sass generates `:root` variables or scoped classes
   - **Tailwind:** Convert semantic tokens to Tailwind config
   - **Figma:** Export to Figma Tokens plugin format
   - **iOS/Android:** Generate native token formats (Swift/Kotlin)
   - **Storybook:** Auto-generate token reference docs

### Phase 3: Distribution

4. **Publish:**
   - npm: @company/design-tokens
   - CDN: design-tokens@latest.css
   - Design tools: Figma, Sketch plugins
   - Repository: GitHub release + tag

### Phase 4: Consumption

5. **Teams consume:**
   - Web: `npm install @company/design-tokens`
   - Mobile: Native token imports
   - Figma: Sync plugin pull from git

---

## Integration points

### Figma Tokens plugin

```bash
# Configure Figma Tokens plugin to sync from git
# Source: https://github.com/IBuySpy-Shared/basecoat-sheen (or internal mirror)
# File: tokens/semantic/figma.json
# Sync: Manual pull or GitHub Action webhook
```

### CSS/Tailwind build

```bash
# PostCSS + Sass transforms tokens to CSS
npm run build:css     # outputs design-tokens.css
npm run build:tw      # outputs tailwind.config.js
```

### Storybook documentation

```bash
# Auto-generate design token reference from .tokens.json
npm run build:docs:tokens
# Outputs: stories/foundations/Tokens.stories.mdx
```

### GitHub Actions

```yaml
- name: Validate token schema
  run: ./scripts/diagnose-sheen.ps1 --validate-tokens

- name: Build materialized outputs
  run: |
    npm run build:css
    npm run build:tw
    npm run build:figma
    npm run build:native

- name: Publish to npm + CDN
  run: npm publish
```

### Version control

- Track `.tokens.json` in git (all decisions auditable)
- Tag releases: `v1.0.0`, `v1.1.0` (semver)
- CHANGELOG.md documents token changes per version
- Easy rollback: `git checkout v1.0.0` + rebuild

---

## Token structure

Example semantic token setup:

```json
{
  "color": {
    "surface": {
      "$value": "{color.palette.neutral.0}",
      "$type": "color",
      "$description": "Primary background color"
    },
    "on-surface": {
      "$value": "{color.palette.neutral.900}",
      "$type": "color",
      "$description": "Text on surface"
    }
  },
  "component": {
    "button": {
      "padding": {
        "$value": "{spacing.2} {spacing.4}",
        "$type": "dimension",
        "$description": "Button default padding"
      }
    }
  }
}
```

---

## FAQ

**Q: How to sync tokens with Figma?**

A: Install Figma Tokens plugin, import from git (`.tokens/semantic/figma.json`). Sync manually or via GitHub Action webhook.

**Q: Versioning strategy?**

A: Semver per token schema:
- Major: core token removal, semantic layer structure change
- Minor: new tokens, new themes, new component tokens
- Patch: bug fixes, value corrections, docs updates

**Q: Can we extend tokens?**

A: Yes, add custom tokens at semantic layer (e.g., `product-a.color.brand-primary`). Reference core for consistency. Document provenance in `.tokens.json`.

**Q: How to handle third-party tokens (e.g., brand partner)?**

A: Merge into semantic layer with clear namespace (e.g., `partner.brand.*`). Document source and license. Version together with your tokens.

**Q: Multi-brand support?**

A: Use themes. Define separate theme files for each brand (`themes/brand-a.json`, `themes/brand-b.json`). All reference same semantic tokens.

**Q: Token resolution order?**

A: Component tokens override semantic, semantic override core. Clear precedence in build pipeline (or diagnostic report).

**Q: How to deprecate a token?**

A: Mark in `.tokens.json` with `$deprecated: true` and migration note. Include in CHANGELOG. Provide search-and-replace script for consumers.

**Q: CI validation — what checks?**

A: `diagnose-sheen.ps1` checks: schema validity, naming conventions, no broken references, contrast compliance, theme coverage.

---

## Success metrics

- **Token coverage:** 100% of design decisions in tokens
- **Platform parity:** Same tokens render consistently across web/mobile/print
- **Build time:** <10 seconds for full materialization
- **Adoption:** All consuming teams using tokens (no hardcoded values)
- **Compliance:** 100% audit trail (git history + release tags)

---

## Next steps

1. Save `.sheen.yml` config above
2. Run `sync.ps1` or `sync.sh`
3. Set up build pipeline: CSS, Tailwind, Figma export
4. Add CI validation: `diagnose-sheen.ps1 --validate-tokens`
5. Publish first release to npm/CDN
6. Document token consumption in team wikis

---

## Transition paths

- **To Cross-Functional:** Add skills/agents if your product teams want AI-driven design reviews
- **To Cross-Org:** Distribute token-only config to multiple teams with central version pinning
