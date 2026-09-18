---
name: style-guide-authoring
compatibility: [github-copilot-cli]
description: "Compile or review guides from approved guidance. USE FOR: style-guide compilation, pattern library publication, guideline consolidation, author an offline HTML guide, refresh a generated guide, check guide freshness. DO NOT USE FOR: single-component-only specs, token validation scripts, inventing an identity, choosing a theme, copying a reference deck, generating reporting dashboards."
category: governance
metadata:
  category: governance
  maturity: stable
  audience: [designer, developer]
  pillar: governance
allowed-tools: []
---

# style-guide-authoring

Compile or review style guides from approved product, brand, pattern and design-system guidance. This skill is orchestrated by `design-reviewer`; domain decisions remain with their specialist owners.

## Required local references

Before acting, read:
- `references/guide-contract.md`
- `references/module-recipes.md`
- `references/input-provenance.md` for source IDs, scope, status and freshness precedence
- `templates/guide-outline.md` when authoring or refreshing

## Workflow
1. Classify request intent as audit, template, generate, refresh or freshness check.
2. Select delivery format: explicit request first, then existing guide format for refresh, otherwise Markdown.
3. Separate structural references from approved downstream inputs; never promote reference content into output.
4. Map each module to a permitted source ID, scope, status, revision and retained specialist owner (`references/input-provenance.md`); conflicting approved sources for one scope are BLOCKED, missing evidence stays unresolved.
5. Perform only the selected operation and deliver the scoped output.

## Guardrails
- Do not approve out-of-policy changes without documented exception path.
- Do not hide uncertainty in compliance judgments.
- Do not recommend changes without clear ownership and closure criteria.
- Do not conflate style preference with contractual requirement.
- Do not write artifacts, sources or metadata/timestamps for audit-only or freshness-check requests; freshness (CURRENT/STALE/UNKNOWN) is never a promotion to READY.
- Do not require `scripts/*.ps1` in this folder for a downstream/copied skill; an equivalent approved artifact with the same scope and evidence is sufficient.
- Do not publish, configure URLs, package portable HTML, or change application styles without separate authorization.

## Output
- Authoring/template/refresh: the selected Markdown or HTML-profile guide content plus module status, provenance and review-state summary.
- Audit/check: findings, severity, remediation owners, freshness/status and decision log only; no artifact writes.

## Delegates / pairs with
- design-reviewer
- pattern-library
- brand-identity
- logo-usage
- brand-voice-tone
- imagery-illustration
- design-tokens
- theming
- information-architecture
- accessibility-audit
- color-contrast-check
