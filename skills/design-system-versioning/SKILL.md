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

Classify design-system changes and plan migrations/deprecations for safe consumer upgrades.

## Workflow
1. Collect current version, token/component diffs, and affected consumers.
2. Read and apply the [versioning contract](references/versioning-contract.md): classification table, migration/deprecation scenarios, artifact roles, and schema.
3. Determine semver impact and document breaking changes, consumer impact, find/replace steps, and deprecation/alias timeline.
4. Produce upgrade guidance and a Keep a Changelog entry; route brand and contrast impacts to their owners.

## Guardrails
- Token renames/removals, breaking component APIs, and theme structure changes are MAJOR.
- New tokens/components and additive component APIs are MINOR; within-theme token value changes are PATCH, with contrast review.
- Do not substitute application/API versioning or package release automation.
- Keep migration/deprecation guidance consumer-facing; a classification is not release authorization.

## Output
- Downstream migration guide, deprecation notice, changelog entry, and breaking-change impact assessment.
- Reference `design-update` schema: bump/current/next versions, breaking changes, deprecations, migration steps, consumer impact.

## Delegates / pairs with
- Triggered by: `design-system-architect` (planning), `design-reviewer` (PR review).
- Feeds: `brand-steward` (brand tokens), `accessibility-auditor` (contrast impact).
- Consumers: downstream teams onboarding via `sheen-onboard`.
