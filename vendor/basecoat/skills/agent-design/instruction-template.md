---
name: "<instruction-name>"
description: "<One-line description of what this instruction enforces or guides.>"
applyTo: "<glob pattern — e.g., '**/*.ts' or 'src/api/**'>"
---

# <Instruction Display Name>

## Purpose

<One to two sentences explaining what behavior this instruction enforces and why it matters.>

## Rules

- <Rule 1 — concrete, actionable directive.>
- <Rule 2 — use imperative voice.>
- <Rule 3 — keep each rule to one sentence.>
- <Rule 4>

## Examples

### Correct

```
<Show a brief example of code or text that follows the rules.>
```

### Incorrect

```
<Show a brief example that violates the rules, with a comment explaining why.>
```

## Scope

- **Applies to:** <describe which files, folders, or contexts this instruction covers.>
- **Does not apply to:** <explicit exclusions, if any.>

## Conventions

- Instruction filenames: `<kebab-case-name>.instructions.md`
- Place in the `instructions/` directory at the repository root, or in a subdirectory for scoped instructions.
- The `applyTo` frontmatter field uses glob patterns to define where the instruction is active.
- Keep instructions focused — one concern per file. Combine only closely related rules.
