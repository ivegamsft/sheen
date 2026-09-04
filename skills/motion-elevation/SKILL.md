---
name: motion-elevation
compatibility: [github-copilot-cli]
description: "Use when defining or validating motion tokens, elevation rules, and material/translucency guidance. USE FOR: duration and easing tokens, elevation level rules, material/translucency guidance. DO NOT USE FOR: full interaction state specs, usability heuristic reviews."
category: foundation
metadata:
  category: foundation
  maturity: beta
  audience: [designer, developer]
  pillar: foundations
allowed-tools: []
---

# motion-elevation

Define motion, elevation, and material behavior primitives.

## Workflow
1. Inventory existing primitives, aliases, and constraints for the target surfaces.
2. Define normalized foundation rules (naming, scales, and semantic intent).
3. Produce cross-theme mappings and list deliberate exceptions with rationale.
4. Validate compatibility with related foundations and downstream components.
5. Publish migration notes for safe adoption and backwards compatibility.

## Guardrails
- Do not introduce breaking foundation changes without migration guidance.
- Do not encode one-off product exceptions as global foundation rules.
- Do not bypass accessibility constraints when shaping primitives.
- Do not duplicate semantics already covered by adjacent foundation skills.
- Do not prescribe animation libraries, timing/easing values, or a specific
  aesthetic when reviewing motion concentration.

## Output
- Foundation decision brief with naming/scales and constraints.
- Impact and migration checklist for affected components and themes.

## Delegates / pairs with
- theming
- component-spec

## Motion Concentration & Attention-Budget Review (#184)

Manages the page/flow-level attention budget so individually acceptable
effects don't accumulate into a noisy, generic experience:

- **Motion inventory.** List every user-triggered (hover, press, drag,
  action transitions) and non-user-triggered (autoplay, entrance, ambient,
  background) motion across the experience.
- **Attention purpose.** Every non-user-triggered motion must state an
  explicit attention or comprehension purpose (for example, directing focus
  to a new status); motion without a stated purpose is a finding, not a
  default.
- **Concentration over repetition.** Prefer a small number of coordinated,
  prioritized moments over the same entrance/hover effect repeated
  section-by-section; flag repeated generic effects and conflicting focal
  points competing for attention.
- **Interaction vs. decorative.** Separate state-explaining interaction
  motion (feedback for a user action or system status) from decorative
  motion (mood/branding only); judge interaction motion on comprehension and
  decorative motion on restraint.
- **Reduced-motion check.** Confirm a reduced-motion alternative exists for
  every non-essential motion and that it preserves task completion and
  status comprehension, not just a shorter version of the same effect.
- **Cumulative density.** Score total concurrent and per-scroll motion
  density; flag when it exceeds what a single moment could coordinate and
  produce a prioritized remediation list (which moments stay, which are
  merged or removed).

This review never prescribes animation libraries, timing/easing values, or
a specific aesthetic.
