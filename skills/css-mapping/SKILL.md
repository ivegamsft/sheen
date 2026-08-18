---
name: css-mapping
compatibility: [github-copilot-cli]
description: "Use when inventorying existing CSS to identify token candidates, detect framework usage, or map raw values to design tokens. USE FOR: css inventory mapping, framework detection, token candidate extraction. DO NOT USE FOR: creating new semantic token models, design review facilitation."
category: mapping
metadata:
  category: mapping
  maturity: beta
  audience: [designer, developer]
  pillar: mapping
allowed-tools: []
---

# css-mapping

Map existing CSS styles into token candidates.

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
- design-tokens
- design-audit
