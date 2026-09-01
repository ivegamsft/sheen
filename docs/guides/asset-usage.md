# Skill / Agent / Instruction Usage

Use this page when you need to choose the right asset type for a task.

| If you need... | Use... | Why |
|---|---|---|
| A focused workflow for one task | **Skill** | Best for repeatable, bounded work |
| A multi-step role with routing | **Agent** | Best for orchestrated work across skills |
| Ambient guidance for matching design/UI files | **Instruction** | Applies automatically only where the rule is actionable |
| Portable design values | **Token** | Best for theming and downstream implementation |

## Rule of thumb

- choose the narrowest asset that solves the problem
- use agents only when a single skill is too small
- use instructions when behavior must stay consistent across matching file paths
- scope instructions to the narrowest design/UI globs that preserve their intent;
  use a skill for full audits that should be explicitly requested

## Where to look next

- [Skills catalog](../reference/skills-catalog.md)
- [Agent roster](../reference/agent-roster.md)
- [`.sheen.yml` guide](sheen-yml.md)
