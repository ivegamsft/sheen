# Core concepts

These are the terms you need to understand sheen quickly.

| Concept | What it means | Why it matters |
|---|---|---|
| **Skill** | A reusable workflow asset that handles a focused design task | Helps teams route the right action fast |
| **Agent** | A composed role that can combine skills into a broader workflow | Useful for multi-step or cross-functional work |
| **Instruction** | Ambient guidance that stays in force across consumer repos | Keeps behavior and language consistent |
| **Token** | A DTCG design token with `$type`, `$value`, and `$description` | Supports themeable, portable design systems |
| **Theme** | A semantic override set for light, dark, high-contrast, or brand variants | Makes tokens usable across surfaces |
| **Consumer** | A repository that syncs sheen assets through `.sheen.yml` | Defines where adoption actually happens |
| **Manifest** | The record of what sync placed into a consumer repo | Supports traceability and rollback |

## The adoption layers

1. **Discovery** — learn what sheen contains and where to start
2. **Getting started** — set up a first sync and choose a rollout mode
3. **Integration patterns** — wire sheen into a real workflow
4. **Reference** — read the deep docs when you need exact behavior
5. **Support** — find fixes and common answers

## The mental model

Sheen is a finish coat over basecoat. Basecoat provides the governance
foundation; sheen packages the design and token layer that teams consume.
