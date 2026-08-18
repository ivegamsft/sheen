---
name: i18n-framework-mapping
compatibility: [github-copilot-cli]
description: "Use when detecting i18n framework usage and inventorying locale coverage and translation key gaps. USE FOR: i18n framework detection, locale coverage inventory, translation key gap mapping. DO NOT USE FOR: i18n strategy design, component variants."
category: mapping
metadata:
  category: mapping
  maturity: beta
  audience: [designer, developer]
  pillar: mapping
allowed-tools: []
---

# i18n-framework-mapping

Detect and map internationalization framework usage and coverage.

## Workflow
1. Inventory source artifacts and classify mapping candidates.
2. Map each candidate to target contracts with confidence labels.
3. Flag collisions and ambiguities requiring adjudication.
4. Quantify coverage and prioritize unresolved gaps.
5. Deliver a migration-ready mapping table with next actions.

## Guardrails
- Do not infer mappings without traceable source evidence.
- Do not collapse distinct concepts into a single target key.
- Do not overwrite canonical mappings without conflict review.
- Do not report completion while unresolved gaps remain untracked.

## Output
- Source-to-target mapping matrix with confidence levels.
- Gap/conflict report prioritized for remediation.

## Delegates / pairs with
- multilingual
- design-audit
