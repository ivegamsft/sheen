# Adoption Measurement Contract (#66)

Read before measuring adoption. Apply all metric definitions/targets and the
report schema; scenarios cover tokens, components, teams, and deprecations.
Example paths and deprecation tables are supplied by the downstream project.

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

## Report artifact roles

These suggested downstream artifact names are not bundled template files.
Author them from the metrics and schema in this reference.

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
