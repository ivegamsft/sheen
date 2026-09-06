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

Measure production token/component adoption, team drift, and hardcoded or stale usage.

## Workflow
1. Scope the codebase, team, or file; load token definitions, component inventory, and downstream deprecation decisions.
2. Read and apply the [measurement contract](references/measurement-contract.md): metrics, targets, scenarios, artifact roles, and schema.
3. Count semantic-token coverage, component adoption, hardcoded values, invalid/deprecated references, and team coverage.
4. Rank drifting files, produce the scorecard, and recommend deep dives or cleanup.

## Guardrails
- Preserve targets: token coverage >90%, component adoption >80%, drift <5%, teams with >80% token coverage >75%, stale usage 0.
- Distinguish unused tokens, hardcoded values, stale references, and custom components; report observed scope and evidence rather than implied full coverage.
- Do not substitute application performance monitoring, error tracking, or unrelated user analytics.

## Output
- Downstream token usage report, team/product scorecard, and file-level drift heatmap.
- Reference `audit-report` schema: scope, coverage/adoption percentages, hardcoded/stale counts, top drifting files, A–F adoption grade, recommendations.

## Delegates / pairs with
- Triggered by: `design-system-architect` (quarterly review), `design-reviewer` (pre-major-release).
- Feeds: `design-drift-detection` (component deep dive), `design-system-versioning` (deprecation cleanup).
- Reports to: engineering managers and design system owners.
