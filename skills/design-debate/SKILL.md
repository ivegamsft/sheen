---
name: design-debate
compatibility: [github-copilot-cli]
description: "Use when you need to choose between competing design approaches with explicit criteria and documented tradeoffs. USE FOR: option tradeoff analysis, design decision records (ADRs), criteria-based comparisons with evidence. DO NOT USE FOR: single artifact polish reviews, token-only mechanical edits."
category: lifecycle
metadata:
  category: lifecycle
  maturity: beta
  audience: [designer, developer]
  pillar: lifecycle
allowed-tools: []
---
# design-debate

Facilitate structured tradeoff analysis between design options.

## Workflow
1. Frame the decision with a one-sentence problem statement, constraints, non-goals, and decision deadline.
2. Define evaluation criteria (for example usability impact, accessibility risk, implementation complexity, delivery speed, and long-term maintainability) and weight them.
3. Generate at least three viable options, including a conservative baseline and a higher-upside alternative.
4. Score each option against each criterion with explicit evidence, assumptions, and confidence level.
5. Identify key risks, reversibility, and blast radius for the top two options, then run a sensitivity check on the top-weighted criterion.
6. Recommend one option, name the trigger conditions that would change the decision, and capture the outcome as a decision record.

## Guardrails
- Do not treat opinion as evidence; every score must have a rationale or source.
- Do not declare accessibility, security, or performance compliance; route deep validation to specialist skills.
- Do not collapse into implementation planning; this skill chooses direction, not execution details.
- Do not produce a binary "A is better" outcome without recording tradeoffs and decision conditions.

## Output
- Decision brief containing:
  - decision statement and scope
  - weighted criteria table
  - option comparison matrix with evidence
  - risk and reversibility analysis
  - recommended option with confidence and fallback trigger
- ADR-style summary entry suitable for `docs/` or PR discussion.

## Delegates / pairs with
- design-review
- craft-quality
- accessibility-audit
- secure-ux
- web-usability-review
