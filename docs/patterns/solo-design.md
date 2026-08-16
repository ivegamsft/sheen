# Pattern 1: Solo-Design

Individual designer, small project, quick turnaround, no cross-team dependencies.

## Profile

**Best fit:**
- Solo designers or very small design teams
- Personal portfolios, side projects, client work
- Quick iterations with design review focus
- No token infrastructure needed yet

**Duration:** weeks to months

**Team size:** 1 designer

**Why this pattern:**
- Fast setup, minimal overhead
- Focused skill set (design review, token audit, accessibility review)
- No sync/merge bottlenecks
- Opt-in to agents/tokens as needed
- Easy to migrate to cross-functional if work expands

---

## .sheen.yml config

Place this at your repo root and run `sync.ps1` or `sync.sh`.

```yaml
# Solo Designer Mode — lean setup for individual design work
source: https://github.com/IBuySpy-Shared/basecoat-sheen.git
ref: main

# Include only design-focused skills (no engineering agents)
skills:
  - design-review
  - token-audit
  - accessibility-audit
  - design-system-audit

# Include core design principles for ambient guidance
instructions:
  - sheen-10-core-design-principles
  - sheen-40-web-usability
  - sheen-90-standards-conformance

# Optional: tokens for local design system
# Omit if using Figma design tokens instead
themes: []  # exclude tokens (or include if doing CSS/component work)
```

---

## Workflow

1. **Copy config:** Save the above `.sheen.yml` at your repo root
2. **Run sync:** Execute `sync.ps1` (Windows) or `sync.sh` (Unix)
3. **Invoke skills:** In Copilot chat, use skill routing:
   - `design-review: review this homepage layout`
   - `accessibility-audit: check this form for WCAG AA compliance`
   - `token-audit: validate my color palette`
4. **Iterate:** Use feedback from skills to refine designs
5. **Handoff:** Export principles, token decisions, accessibility checklist to the team

---

## Integration points

### Figma

- Reference sheen design principles when making mockup decisions
- Use accessibility audit results to validate Figma components
- Link to sheen docs in design specs (share principles with hand-off)

### Component library

- Use design-system-audit skill to review component patterns
- Validate design tokens if adding CSS/Tailwind later
- Document reusable component patterns discovered via reviews

### Handoff to engineering

1. Export design principles from Copilot chat
2. Document token decisions (color palette, type scale, spacing)
3. Share accessibility checklist (contrast, labels, interaction patterns)
4. Link to this pattern doc as reference

---

## FAQ

**Q: Can I add skills later?**

A: Yes, update `.sheen.yml`, re-run `sync.*`, and new skills are available. No data loss.

**Q: What if my project grows to a team?**

A: Migrate to cross-functional pattern (see [Pattern 2](cross-functional.md)). Update `.sheen.yml` to include all skills/agents and themes: [light, dark]. Re-sync and you're ready.

**Q: How often to re-sync?**

A: Monthly is reasonable for `ref: main`. Set a calendar reminder. For production, pin to a release tag and only upgrade manually.

**Q: Can I disable a skill?**

A: Yes, remove it from the `skills` list in `.sheen.yml`, re-sync. Skill data is cleaned up automatically.

**Q: Do I have to use AI agents?**

A: No agents in this pattern by design. If you want structured design reviews, add the design-reviewer agent in skills.

**Q: What if I need custom tokens?**

A: Keep tokens omitted (`themes: []`) and use Figma instead. If you later add CSS/Tailwind, enable tokens and define semantic tokens in `.tokens.json`.

---

## Success metrics

- **Design review time:** 20% reduction (faster feedback via skill)
- **Accessibility issues:** Caught at design phase (before hand-off)
- **Handoff clarity:** Principles documented and actionable
- **Time to first insight:** <5 minutes (no setup overhead)

---

## Next steps

1. Save the `.sheen.yml` config above
2. Run `sync.ps1` or `sync.sh`
3. Try one skill: `design-review: review this layout`
4. Iterate based on feedback
5. Document principles for hand-off when ready

---

## Transition path

If your project grows:
- [Cross-Functional](cross-functional.md) — add engineering, tokens, shared governance
