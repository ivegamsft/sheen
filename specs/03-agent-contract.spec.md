# Spec 03 — Agent Contract

> Normative spec for `agents/`. Implements root SPEC §4, §9.

## 1. Files

```
agents/<role>.agent.md            # required — the persona
agents/<role>.agent.eval.yaml     # required — routing/behavior eval
```

`<role>` is kebab-case (e.g. `design-reviewer`).

## 2. `*.agent.md` frontmatter

```yaml
---
name: <role>
compatibility: [github-copilot-cli]
description: "Design-role agent that … . Invoke for <situations>."
metadata:
  maturity: draft
  pillar: <primary pillar>
composes:
  skills: [<skill-a>, <skill-b>]        # skills this agent orchestrates
  instructions: [sheen-10-core-design-principles, …]
allowed-tools: [...]                     # least-privilege union of needs
---
```

## 3. Body

Required sections:

1. **Role & mandate** — what the agent owns and its decision authority.
2. **Operating principles** — appeals to the sheen design values (root SPEC §2).
3. **Playbook** — how it sequences its composed skills for common requests.
4. **Handoffs** — which agent/skill it routes to when work leaves its mandate.
5. **Definition of done** — what "good" output looks like.

## 4. Roster (target)

| Agent | Mandate | Composes (primary) |
|---|---|---|
| `brand-steward` | Brand identity, voice, logo, imagery integrity | `brand-identity`, `brand-voice-tone`, `logo-usage`, `imagery-illustration` |
| `design-system-architect` | Tokens, components, theming coherence | `design-tokens`, `theming`, `component-spec`, `design-system-audit` |
| `ux-designer` | Journeys, wireframes, interaction & usability | `wireframing`, `ui-states-interaction`, `web-usability-review`, `responsive-design` |
| `information-architect` | Structure, navigation, taxonomy, ontology | `information-architecture`, `navigation-design`, `taxonomy`, `ontology` |
| `accessibility-auditor` | WCAG + NN/g heuristics conformance | `accessibility-audit`, `color-contrast-check`, `usability-mapping` |
| `design-reviewer` | Craft-bar critique & tradeoff facilitation | `design-review`, `design-debate`, `craft-quality` |

## 5. Eval

`*.agent.eval.yaml` mirrors the skill eval shape (spec 02 §4) but asserts on
role activation and correct skill routing, with ≥3 positive and ≥2 negative
scenarios (a negative SHOULD target a neighboring agent's mandate).

## 6. Rules

- Agents compose skills; they MUST NOT duplicate skill logic inline.
- `composes.skills` MUST reference skills that exist in the catalog (drift fails
  CI — spec 05).
- Agents carry the same least-privilege `allowed-tools` discipline as skills.
