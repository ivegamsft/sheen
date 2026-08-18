---
name: web-usability-review
compatibility: [github-copilot-cli]
description: "Heuristic usability evaluation grounded in NN/g and ISO 9241 principles. USE FOR: reviewing flow usability, scoring heuristic violations, generating prioritized usability recommendations. DO NOT USE FOR: standards-based accessibility conformance audits, creating new token primitives."
category: usability
metadata:
  category: usability
  maturity: stable
  audience: [designer, developer]
  pillar: usability
allowed-tools: []
---
# Web Usability Review

Review a page or flow against usability heuristics and produce actionable findings.

## Workflow
1. Define target flow and primary user tasks.
2. Walk the experience against NN/g heuristics and ISO 9241 dialogue principles.
3. Capture friction points, severity, and affected user outcomes.
4. Prioritize fixes by impact-to-effort and dependency risk.
5. Present recommendations with measurable success criteria.

## Guardrails
- Do not frame subjective style preference as usability failure.
- Do not skip task-level context when reporting findings.
- Do not substitute a11y conformance reporting for usability analysis.

## Output
- Usability findings report with severity-ranked recommendations.
- Improvement plan tied to user-task outcomes.

## Delegates / pairs with
- `usability-mapping`, `content-hierarchy`, `responsive-design`
- `accessibility-audit`

