---
name: design-system-versioning
compatibility: [github-copilot-cli]
description: "Use when managing design system versioning, planning breaking changes, or authoring migration guides. USE FOR: bump design system semver, classify a token rename as breaking vs non-breaking, author a migration guide for a major version, generate a changelog from token and component diffs, plan a deprecation timeline. DO NOT USE FOR: application feature versioning, API semver decisions unrelated to design, package release automation."
category: development
metadata:
  category: development
  maturity: stable
  audience:
    - developer
    - designer
allowed-tools: []
---
# Design System Versioning Skill

Apply semantic versioning discipline to a design system — classifying changes, authoring migration guides, and managing deprecation timelines so consumers can upgrade safely.

## Closes

GitHub issue #61 — `feat(skill): design-system-versioning — semver decisions, migration guides, breaking-change impact`

## Change Classification

| Change Type | SemVer Impact | Example |
|---|---|---|
| New token added | MINOR | `--color-action-warning` added |
| Token value change (within theme) | PATCH | `--color-action-primary` lightness tweak |
| Token rename | MAJOR | `--color-brand-blue` → `--color-action-primary` |
| Token removal | MAJOR | `--color-deprecated-red` removed |
| New component added | MINOR | `<sheen-tooltip>` added |
| Component API change (additive) | MINOR | New optional prop added |
| Component API change (breaking) | MAJOR | Required prop renamed |
| Theme structure change | MAJOR | `light.tokens.json` key hierarchy changed |

## Sample Prompts

### Classify a change

```
@design-system-versioning classify: renaming --color-brand-blue to --color-action-primary
across all 3 themes. What semver bump is required?
```

**Output:**
```
Change: Token rename
Semver: MAJOR (2.0.0 → 3.0.0)
Consumers affected: any file referencing --color-brand-blue
Migration: find/replace --color-brand-blue → --color-action-primary
Deprecation window: 2 minor versions (2.x) with dual-alias bridge
```

### Generate migration guide

```
@design-system-versioning generate a migration guide for upgrading from
basecoat-sheen v2 to v3 based on the token diff in docs/decisions/
```

### Author deprecation plan

```
@design-system-versioning plan the deprecation of --elevation-card-resting
over the next 2 releases
```

### Generate changelog

```
@design-system-versioning generate a CHANGELOG entry for the changes in PR #54
(adds semantic tokens: space, elevation, motion, border)
```

## Templates in This Skill

| Template | Purpose |
|---|---|
| `migration-guide-template.md` | Consumer-facing upgrade guide with find/replace table |
| `deprecation-notice-template.md` | Token/component deprecation notice with timeline |
| `changelog-entry-template.md` | CHANGELOG.md entry following Keep a Changelog format |
| `breaking-change-impact-template.md` | Impact assessment: which consumers are affected |

## Output Schema

```yaml
discriminator: design-update
semver_bump: major | minor | patch
current_version: string
next_version: string
breaking_changes: [string]
deprecations: [string]
migration_steps: [string]
consumer_impact: low | medium | high
```

## Agent Pairing

- Triggered by: `design-system-architect` (planning change), `design-reviewer` (reviewing PR)
- Feeds: `brand-steward` (brand token changes), `accessibility-auditor` (contrast impact of value changes)
- Consumer-facing: migration guide consumed by downstream teams onboarding via `sheen-onboard`
