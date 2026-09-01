# Pattern 2: Cross-Functional

Shared repo, design + engineering teams, design tokens feed component library, unified governance.

## Profile

**Best fit:**
- Shared monorepo or design system repo
- Design + engineering teams collaborate daily
- Token-driven component workflow
- Storybook, component library, or shared CSS

**Duration:** ongoing (long-lived)

**Team size:** 2+ designers + engineers

**Why this pattern:**
- Unified governance (one source of truth for tokens + principles)
- Designers + engineers speak same language (skills + instructions)
- Tokens flow from design → CSS/Storybook → production
- Design decisions codified, enforced, and tracked

---

## .sheen.yml config

Place this at your shared repo root and commit to version control.

```yaml
# Cross-Functional Mode — shared design + eng governance
source: https://github.com/IBuySpy-Shared/basecoat-sheen.git
ref: v0.5.0  # pin to release for stability (upgrade quarterly)

# Include all assets for maximum collaboration
skills: []    # all skills
agents: []    # all agents
instructions: []  # all layers

# Materialize themes for CSS and Figma
themes: [light, dark, high-contrast]
```

---

## Workflow

### Phase 1: Design → Token Definition

1. **Designers define tokens:** Edit `.tokens.json` files (semantic layer)
2. **Token audit:** Run `token-audit` skill in Copilot
   - Checks token resolution (no broken references)
   - Validates naming conventions (sheen vocabulary)
   - Flags missing aliases

### Phase 2: Token Materialization & CI

3. **Build tokens:** Run build script (e.g., `npm run build:tokens`)
   - Generates CSS custom properties
   - Outputs Tailwind config
   - Exports Figma token file
4. **CI validation:** Integrate `diagnose-sheen.ps1` into GitHub Actions
   - Validates token schema
   - Checks theme coverage (every semantic token in every theme)
   - Ensures token names follow sheen conventions
   - Blocks merge if validation fails

### Phase 3: Engineering → Component Implementation

5. **Consume tokens in code:** Storybook components import CSS variables or Tailwind
6. **Design review:** PR automation invokes design-reviewer agent
   - Checks component decisions against design principles
   - Flags accessibility issues (contrast, labels, states)
   - Suggests token usage improvements

### Phase 4: Review & Merge

7. **Code review:** Standard PR review + design-reviewer feedback
8. **Merge:** CI gates ensure tokens, components, and docs are in sync
9. **Publish:** Deploy tokens to npm, CDN, or design tools

---

## Integration points

### Token materialization

- **CSS:** PostCSS/Sass plugin reads `.tokens.json`, outputs CSS custom properties
- **Tailwind:** Custom theme file referencing semantic token values
- **Figma:** Figma Tokens plugin imports token JSON, syncs design file
- **iOS/Android:** Export native token formats from semantic layer

### CI/CD gates

**GitHub Actions example:**

```yaml
- name: Validate sheen tokens
  run: ./scripts/diagnose-sheen.ps1 --validate-tokens
  
- name: Build token outputs
  run: npm run build:tokens
  
- name: Ensure Figma sync
  run: npm run sync:figma-tokens
```

### Design + code review

- Link `design-reviewer` agent to all PRs touching components or tokens
- Tag design team for style decisions; engineers for accessibility/performance
- Documented decisions in PR templates (link to token changes, principles applied)

### Storybook integration

- Load tokens as design data
- Display design principles alongside components
- Show token usage examples (CSS, Tailwind, raw values)
- Include sheen audit results in component docs

### Version control

- Track token changes in git history (`.tokens.json`)
- CHANGELOG.md documents token additions and breaking changes
- Rollback: `git revert` + `npm run build:tokens` (deterministic, safe)

---

## Governance structure

### Token ownership

- **Designers propose:** New tokens, semantic aliases, theme changes
- **Engineers review:** CSS feasibility, performance, browser support
- **Approval:** Joint design/eng sign-off before merge

### Design principles

- **Source:** sheen instructions (loaded when the active files match their
  design/UI scopes)
- **Updates:** Quarterly review by design team
- **Enforcement:** design-reviewer agent flags violations in PRs

### Breaking changes

- **Policy:** Follow semver (major.minor.patch)
  - Major: token schema changes (new `$type`), semantic removal
  - Minor: new tokens, new themes, backward-compatible additions
  - Patch: bug fixes, docs updates
- **Rollback:** Always supported (git revert, re-build tokens)

---

## FAQ

**Q: Who owns token changes?**

A: Design team proposes; engineering reviews for CSS feasibility. Joint approval before merge. Link PRs to design decisions.

**Q: How do we version tokens?**

A: Follow semver (major.minor.patch based on token schema impact). Tag releases in git and CHANGELOG.md.

**Q: Can engineering override tokens?**

A: Yes, via CSS variable overrides or Tailwind modifiers. But document why and link to decision (PR comment or issue).

**Q: How do we handle theme conflicts?**

A: design-reviewer + code-review agents flag style conflicts. Resolve in PR review, test in multiple themes.

**Q: What if designers and engineers disagree on a token value?**

A: Create an ADR (architecture decision record) linking the token, principle, and resolution. Link to PR.

**Q: Can we extend tokens at the component level?**

A: Yes, add component-specific tokens (e.g., `component.button.padding-override`) in semantic layer. Document provenance.

**Q: How to test theme coverage?**

A: Run `diagnose-sheen.ps1 --validate-themes`. Fails if a semantic token is missing in any theme.

---

## Success metrics

- **Token consistency:** 95%+ across all platforms (web, mobile, print)
- **Design-to-code time:** 30% faster (tokens pre-defined)
- **Accessibility score:** Baseline 85+ WCAG 2.2 AA (enforced in CI)
- **PR cycle time:** Reduced rework (design review happens early)
- **Design drift:** Zero (all decisions tracked in git + `.sheen.manifest.json`)

---

## Next steps

1. Save the `.sheen.yml` config above
2. Run `sync.ps1` or `sync.sh`
3. Set up CI gate: Add `diagnose-sheen.ps1` to GitHub Actions
4. Establish token ownership policy (who can edit `.tokens.json`)
5. Run first token audit: `token-audit` skill
6. Pin release tag once confident

---

## Transition paths

- **From Solo-Design:** Add engineers, update config to include all skills, add tokens
- **To Cross-Org:** Keep same config, add federated token sources (see Pattern 3)
