# Manual vs. Automation Decision Rubric

Use this rubric to classify each behavior or test scenario into one of three categories: **manual-only**, **automate-now**, or **hybrid**. Every row must be filled in with a justification — no implicit scope.

## Classification Definitions

| Classification | Meaning |
| --- | --- |
| **Manual-only** | Human judgment is required. The behavior is too exploratory, context-dependent, or infrequently run to justify the cost of automation right now. |
| **Automate-now** | The behavior is stable, deterministic, repeated frequently enough, and high-value enough that not automating it is a regression risk. |
| **Hybrid** | The core happy path can be scripted, but edge cases, UI quality, or environmental variation still require a manual pass alongside the automated check. |

## Risk Scoring Factors

Score each factor from 1 (low) to 3 (high) when a more rigorous classification is needed:

| Factor | 1 | 2 | 3 |
| --- | --- | --- | --- |
| **Change frequency** | Rarely changes | Changes occasionally | Changes every sprint |
| **Business impact** | Low visibility, easy recovery | Moderate impact | Critical path, data loss risk |
| **Observability** | Output is easily checked | Output requires interpretation | Hard to observe without tooling |
| **Automation value** | High setup cost, low reuse | Moderate reuse | High reuse, deterministic output |

A total score of 8–12 across the four factors is a strong signal for **automate-now**. A score of 4–7 suggests **hybrid**. A score below 4 or where observability is inherently human suggests **manual-only**.

## Rubric Table

Fill in one row per behavior or test scenario.

| # | Behavior / Scenario | Classification | Change Freq | Business Impact | Observability | Automation Value | Score | Justification |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | | | | | | | | |
| 2 | | | | | | | | |
| 3 | | | | | | | | |

## Coverage Boundary Summary

After filling the table, complete this summary:

- **Manual-only scope**: _[describe what stays manual and why]_
- **Automate-now scope**: _[describe what should be scripted immediately]_
- **Hybrid scope**: _[describe what needs both manual and scripted coverage and how they complement each other]_
- **Coverage goal**: _[state the expected manual/automated ratio or threshold if one is defined]_

## Automation Backlog

List automation candidates (automate-now or hybrid items not yet scripted) for handoff to the `strategy-to-automation` agent:

| Candidate | Classification | Priority | Notes |
| --- | --- | --- | --- |
| | | | |
