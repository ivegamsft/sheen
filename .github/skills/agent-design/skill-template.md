---
name: "<skill-name>"
description: "<One-line description with trigger phrases for discovery.>"
---

# <Skill Display Name>

Use this skill when <describe the repeatable problem this skill solves>.

## Workflow

1. <Step 1 — what to do first.>
2. <Step 2 — next action.>
3. <Step 3 — next action.>
4. <Step 4 — validation or review.>

## Guardrails

- <Constraint 1 — what this skill must not do.>
- <Constraint 2 — scope boundary.>
- <Constraint 3 — when to use a different primitive instead.>

## Starter Assets

- Template: `templates/<template-name>.md` (if applicable)
- Examples: `examples/<example-name>.md` (if applicable)

## Folder Structure

```
skills/<skill-name>/
├── SKILL.md              # This file — overview, workflow, guardrails
├── <template-name>.md    # Template or scaffold (optional)
├── templates/            # Additional templates (optional)
│   └── <template>.md
└── examples/             # Worked examples (optional)
    └── <example>.md
```

## Conventions

- The folder name must match the `name` field in frontmatter.
- `SKILL.md` is the entry point — agents and discovery tools look for this file.
- Keep the skill scoped to one clear workflow. Split if responsibilities diverge.
- Put discovery keywords in the `description` field, not only in the body.
