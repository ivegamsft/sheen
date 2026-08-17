---
name: design-adoption-telemetry
compatibility: [github-copilot-cli]
description: "Use when measuring design system adoption in production — tracking token usage, component usage, and drift from the design system in live codebases. USE FOR: generate a design token usage report from a codebase, identify components using hardcoded values instead of tokens, measure design system adoption percentage across a product, track which teams are using vs. drifting from the design system, produce a design adoption scorecard. DO NOT USE FOR: application performance monitoring, error tracking, user analytics unrelated to design system usage."
category: development
metadata:
  category: development
  maturity: stable
  audience:
    - developer
    - designer
    - engineering-manager
allowed-tools: []
---
# Design Adoption Telemetry Skill

Measure and report design system adoption in production codebases — surfacing which tokens and components are used, which teams are drifting, and where hardcoded values are creeping in.

## Closes

GitHub issue #66 — `feat(skill): design-adoption-telemetry — token and component usage analytics in production code`

## Adoption Metrics

| Metric | Description | Target |
|---|---|---|
| Token coverage | % of CSS properties using design tokens vs. hardcoded | > 90% |
| Component adoption | % of UI components from design system vs. custom | > 80% |
| Drift rate | % of token references that don't match current token names | < 5% |
| Team adoption | % of teams with > 80% token coverage | > 75% |
| Stale token usage | References to deprecated tokens still in use | 0 |

## Sample Prompts

### Token usage report

```
@design-adoption-telemetry generate a token usage report for src/
showing which semantic tokens are used, missing, and hardcoded
```

**Output:**
```
## Token Adoption Report: src/

Token coverage: 74% (target: 90%) ⚠️
  Used tokens: 58 / 80 semantic tokens referenced
  Hardcoded values: 23 instances (top offenders: #1a1a1a ×8, 16px ×6)
  Stale tokens: 2 (--color-brand-blue deprecated → --color-action-primary)

Top drifting files:
  src/legacy/checkout.css   — 12 hardcoded values
  src/components/OldCard.tsx — 6 hardcoded values

Recommended: run design-drift-detection on top drifting files
```

### Component adoption report

```
@design-adoption-telemetry measure component adoption across src/components/
against the design system component inventory
```

### Team adoption scorecard

```
@design-adoption-telemetry generate a team adoption scorecard
for the Q3 design system review
```

### Find stale token references

```
@design-adoption-telemetry find all references to deprecated tokens
in src/ based on the deprecation table in docs/decisions/
```

## Templates in This Skill

| Template | Purpose |
|---|---|
| `token-usage-report-template.md` | Codebase token coverage report with hardcoded value inventory |
| `adoption-scorecard-template.md` | Team/product design system adoption scorecard |
| `drift-heatmap-template.md` | File-level drift heatmap sorted by hardcoded value count |

## Output Schema

```yaml
discriminator: audit-report
scope: codebase | team | file
token_coverage_pct: number
component_adoption_pct: number
hardcoded_count: number
stale_token_count: number
top_drifting_files: [string]
adoption_grade: A | B | C | D | F
recommendations: [string]
```

## Agent Pairing

- Triggered by: `design-system-architect` (quarterly review), `design-reviewer` (pre-major-release)
- Feeds: `design-drift-detection` (per-component deep dive), `design-system-versioning` (deprecation cleanup)
- Reports to: engineering managers and design system owners
