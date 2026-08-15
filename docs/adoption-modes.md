# Adoption Modes

Use these profiles to adopt basecoat-sheen at the right depth for your team.
Each mode uses the same sync mechanism (`.sheen.yml` + sync script), so moving
between modes is a config change, not a platform change.

## Mode 1: Lean (solo or low overhead)

**What is included:** a narrow skill allow-list plus core design principles.

**Why choose it:** fastest onboarding with minimal maintenance overhead.

**When to use it:** solo projects, design reviews, early-stage teams validating
workflow fit.

```yaml
# Lean mode: small skill subset + core instruction layer
source: https://github.com/IBuySpy-Shared/basecoat-sheen.git
ref: main
skills:
  - design-review
  - web-usability-review
instructions:
  - sheen-10-core-design-principles
```

Expected outcome:

- Fast first sync
- Immediate review workflow coverage
- Low governance surface area while teams learn the model

## Mode 2: Token-only (design-system governance without AI assets)

**What is included:** token themes and token-focused instruction layers only; no
skills or agents.

**Why choose it:** machine-readable design governance without introducing AI
workflow assets.

**When to use it:** teams with established design systems that need token
consistency, theme parity, and standards gates.

```yaml
# Token-only mode: token governance, no skill/agent sync
source: https://github.com/IBuySpy-Shared/basecoat-sheen.git
ref: main
skills: []
agents: []
instructions:
  - sheen-20-tokens-foundations
themes:
  - light
  - dark
  - high-contrast
```

Expected outcome:

- DTCG token foundations and themes in the consumer repo
- Clear governance constraints without adding agent orchestration
- Easy integration into existing CI token checks

## Mode 3: Full (cross-functional, maximum coverage)

**What is included:** all available sheen assets (skills, agents, instructions,
tokens, and themes).

**Why choose it:** unified design and engineering governance with maximum reuse
across teams.

**When to use it:** cross-functional product teams, multi-repo programs, and
organizations standardizing on shared UX quality bars.

```yaml
# Full mode: sync complete basecoat-sheen catalog
source: https://github.com/IBuySpy-Shared/basecoat-sheen.git
ref: main
# Omit allow-lists to pull full asset inventory
```

Expected outcome:

- Complete governance surface from token definitions to workflow assets
- Shared vocabulary and instruction layers across team roles
- Best fit for scaled adoption and portfolio-level consistency

## How to switch modes safely

1. Edit `.sheen.yml` to the target mode.
2. Run sync in a feature branch.
3. Verify the resulting asset set and CI checks.
4. Merge after team review.

For setup and troubleshooting details, return to
[Quick Start](quick-start.md) and [Onboarding FAQ](onboarding-faq.md).
