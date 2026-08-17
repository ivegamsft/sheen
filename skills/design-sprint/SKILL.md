---
name: design-sprint
compatibility: [github-copilot-cli]
description: "Use when facilitating a design sprint — from problem framing through ideation, prototyping, and user validation. USE FOR: run a GV-style 5-day design sprint, facilitate a 2-hour lightning design sprint, generate How Might We (HMW) questions from a problem brief, produce a sprint map and decision log, create a prototype spec from sprint day-3 storyboard. DO NOT USE FOR: implementing the prototyped solution in production code, project management tooling, user research recruitment."
category: development
metadata:
  category: development
  maturity: stable
  audience:
    - designer
    - product-manager
    - developer
allowed-tools: []
---
# Design Sprint Facilitation Skill

Facilitate end-to-end design sprints — from problem framing and HMW generation through sketching, storyboarding, prototyping, and validation planning.

## Closes

GitHub issue #68 — `feat(skill): design-sprint-facilitation — end-to-end sprint workflow (frame, ideate, prototype, validate)`

## Sprint Formats

| Format | Duration | Best For |
|---|---|---|
| GV Full Sprint | 5 days | Complex, high-stakes problems |
| Lightning Sprint | 4 hours | Narrow, well-defined problems |
| Design Critique | 90 minutes | Existing design iteration |
| Problem Framing | 2 hours | Kickoff / discovery |

## 5-Day Sprint Structure (GV)

| Day | Focus | Output |
|---|---|---|
| Monday | Understand + Map | Problem map, HMW notes, long-term goal |
| Tuesday | Sketch | Crazy 8s, solution sketches |
| Wednesday | Decide | Storyboard, sprint questions |
| Thursday | Prototype | Prototype spec (→ `ux` skill) |
| Friday | Test | Test script, user feedback synthesis |

## Sample Prompts

### Launch a full sprint

```
@design-sprint facilitate a 5-day GV design sprint for the problem:
"Users abandon checkout after reaching the payment screen (68% drop-off)"
```

**Output — Day 1 artifacts:**
```
## Sprint — Day 1: Understand + Map

Long-term goal: Reduce checkout abandonment from 68% to <30% in 6 months

Sprint questions (what could go wrong):
  1. Will users trust a new payment UI if it looks unfamiliar?
  2. Can we reduce form fields without losing legal requirements?
  3. Will mobile users have a worse experience with the new flow?

How Might We notes (top 5):
  HMW make the total cost clear before the payment screen?
  HMW reduce the number of required fields?
  HMW make guest checkout feel as safe as account checkout?
  HMW show progress so users know how close they are to done?
  HMW reassure users about payment security without cluttering the UI?

Sprint map:
  User → Browse → Cart → Checkout → [💥 Payment Screen] → Confirmation
                                        ↑ Target zone
```

### Generate HMW questions

```
@design-sprint generate How Might We questions for:
"Designers spend 3 hours per sprint manually checking token compliance"
```

### Facilitate a lightning sprint

```
@design-sprint run a 4-hour lightning sprint for redesigning the
user onboarding flow
```

### Prototype spec from storyboard

```
@design-sprint convert this Day 3 storyboard to a prototype spec
for the ux skill:
[paste storyboard panels]
```

## Templates in This Skill

| Template | Purpose |
|---|---|
| `sprint-brief-template.md` | Sprint kickoff brief: problem, goal, HMW, sprint questions |
| `sprint-storyboard-template.md` | 8-panel storyboard template for Day 3 |
| `prototype-spec-from-sprint-template.md` | Prototype spec derived from sprint storyboard |
| `test-script-template.md` | Day 5 user test script with task scenarios |
| `sprint-decision-log-template.md` | Sprint decision log with rationale |

## Output Schema

```yaml
discriminator: ia-artifact
sprint_format: gv-full | lightning | critique | framing
day: 1 | 2 | 3 | 4 | 5 | all
long_term_goal: string
sprint_questions: [string]
hmw_notes: [string]
sprint_map: string
decisions: [{decision: string, rationale: string, decider: string}]
prototype_spec_ref: string
```

## Agent Pairing

- Feeds: `ux-designer` (wireframe/prototype spec from Day 3), `information-architect` (IA implications)
- Outputs to: `design-reviewer` (Day 5 test debrief), `design-to-code` (prototype implementation)
- Decision log: feed to `decision-log-capture` for durable record
