---
name: design-sprint
compatibility: [github-copilot-cli]
description: "Use when facilitating a design sprint — from problem framing through ideation, prototyping, and user validation. USE FOR: run a GV-style 5-day design sprint, facilitate a 2-hour lightning design sprint, generate How Might We (HMW) questions from a problem brief, produce a sprint map and decision log, create a prototype spec from sprint day-3 storyboard. DO NOT USE FOR: implementing the prototyped solution in production code, project management tooling, user research recruitment."
category: lifecycle
metadata:
  category: lifecycle
  maturity: stable
  audience:
    - designer
    - product-manager
    - developer
  pillar: lifecycle
allowed-tools: []
---
# Design Sprint Facilitation Skill

Facilitate framing, HMW ideation, sketching, decisions, prototyping, and validation planning.

## Workflow

1. Establish problem, long-term goal, constraints, participants/decider, and duration.
2. Read and apply the [facilitation contract](references/facilitation-contract.md): formats, day outputs, scenarios, artifact roles, and schema.
3. Choose GV (5 days), lightning (4 hours, or explicitly adapted timebox), critique (90 minutes), or framing (2 hours).
4. For GV, map/HMW Monday, sketch Tuesday, decide/storyboard Wednesday, prototype Thursday, test/synthesize Friday; adapt explicitly for shorter formats.
5. Record decisions/rationale/decider, produce prototype and test specs, and hand off follow-up.

## Guardrails

- Preserve problem framing and validation planning; a prototype is not production implementation.
- Do not implement the solution in production, configure project-management tooling, or recruit research participants.
- Record timebox adaptations and unresolved sprint questions rather than implying a shortened sprint completes every full-sprint activity.

## Output

- Downstream kickoff brief, 8-panel storyboard, prototype spec, task-based test script, and decision log.
- Reference `ia-artifact` schema: format/day, goal, questions, HMW notes, sprint map, decisions/rationale/decider, prototype reference.

## Delegates / pairs with

- Feeds: `ux-designer` (Day 3 wireframe/prototype), `information-architect` (IA).
- Outputs: `design-reviewer` (Day 5 debrief), `design-to-code` (prototype implementation).
- `decision-log-capture` preserves the decision log.
