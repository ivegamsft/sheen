---
name: create-design-skill
compatibility: [github-copilot-cli]
description: "Use when this skill is the right fit for the request. Scaffold a new sheen skill that conforms to the skill contract. USE FOR: creating new skill folders and frontmatter, authoring routing eval scenarios, updating catalog entries safely. DO NOT USE FOR: writing instruction-layer files, implementing product feature code."
category: governance
metadata:
  category: governance
  maturity: stable
  audience: [designer, developer]
  pillar: governance
allowed-tools: []
---
# Create Design Skill

Create a new skill package that matches sheen authoring and routing standards.

## Workflow
1. Define one clear workflow and adjacent-skill boundaries.
2. Scaffold `skills/<name>/` with `SKILL.md` and `eval.yaml`.
3. Write frontmatter with required trigger and anti-trigger phrasing.
4. Author concise body sections: workflow, guardrails, output, delegates.
5. Add catalog entry and ensure metadata consistency.

## Guardrails
- Do not merge multiple workflows into one ambiguous skill.
- Do not omit negative eval scenarios for routing disambiguation.
- Do not publish names that break kebab-case or namespace conventions.

## Output
- New skill folder containing `SKILL.md`, `eval.yaml`, and optional templates.
- Catalog/metadata update notes for drift-free integration.

## Delegates / pairs with
- `style-guide-authoring`, `design-review`
- spec references: `specs/02-skill-contract.spec.md`, `specs/07-skill-catalog.spec.md`

