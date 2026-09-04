---
name: design-exploration
compatibility: [github-copilot-cli]
description: "Use when generating new design directions, concepts, or exploring problem spaces before committing to a single path. USE FOR: concept generation, divergent direction exploration, idea synthesis. DO NOT USE FOR: final decision arbitration, wcag audit reporting."
category: lifecycle
metadata:
  category: lifecycle
  maturity: beta
  audience: [designer, developer]
  pillar: lifecycle
allowed-tools: []
---

# design-exploration

Generate and shape new design concepts.

## Workflow
1. Establish lifecycle objective (audit, exploration, handoff, update, or recommendation).
2. Gather current-state evidence and explicit constraints.
3. Produce decision-ready artifacts using this lifecycle method.
4. Validate compatibility with design system, accessibility, and governance.
5. Sequence next actions with owners, dependencies, and risk notes.

## Guardrails
- Do not make directional claims without evidence collection.
- Do not present exploratory artifacts as final sign-off.
- Do not omit risk/dependency notes for downstream execution.
- Do not duplicate ownership of neighboring lifecycle skills without handoff.
- Do not present a generated direction as ready for handoff without a
  recorded anti-template comparison and rejected-alternatives log.

## Output
- Lifecycle artifact set (analysis, decisions, and actions).
- Handoff-ready summary with risks and dependency map.
- Creative-calibration note (subject/audience/primary-job/context grounding,
  one memorable focus with restraint rationale, anti-template comparison,
  and a rejected-alternatives log).

## Delegates / pairs with
- design-debate
- brand-identity

## Creative Calibration (subject-matter grounding & anti-template check, #182)

Before presenting a generated direction as ready for debate or handoff, run
this bounded calibration so it reads as specific to this product, not
interchangeable with an unrelated one:

1. **Ground it.** State the subject matter, target audience, primary
   job-to-be-done, and operating context (device, environment, domain or
   regulatory constraints) in a sentence each; every subsequent choice must
   trace back to at least one of these.
2. **Name one memorable focus.** Identify the single moment, motif, or
   interaction meant to be distinctive, and state why the rest of the
   direction stays restrained in support of it — restraint here is a
   deliberate choice, not a missing idea.
3. **Run the anti-template comparison.** Substitute a plausibly unrelated
   brief (different industry, audience, or primary job) into the direction.
   Any choice that would still read as appropriate for that unrelated brief
   is generic; revise it, or justify it as an intentional shared convention
   (platform pattern, accessibility requirement).
4. **Record rejected alternatives.** List the interchangeable/generic
   options considered and the specific subject/audience/job reason the
   accepted choice was kept instead.
5. **Preserve precedence.** Existing design-system tokens, components, and
   previously accepted product decisions remain authoritative; calibration
   adjusts expression within those constraints, never the constraints
   themselves.

This step evaluates reasoning and distinctiveness only — it never mandates a
visual style, fixed aesthetic, implementation language, or a blacklist of
current trends.
