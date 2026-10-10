---
name: user-research
compatibility: [github-copilot-cli]
description: "Use when preparing client discovery or planning and synthesizing authorized user research. USE FOR: client interview/discovery brief, research planning, evidence-backed interview/persona synthesis, usability test protocol design, assumptions and unknowns register. DO NOT USE FOR: heuristic-only reviews, token schema authoring, backend implementation."
category: governance
metadata:
  category: governance
  maturity: beta
  audience: [designer, developer]
  pillar: governance
allowed-tools: []
---

# user-research

Prepare portable discovery briefs and traceable research artifacts.

## Workflow
1. Read/apply the [discovery contract](references/discovery-contract.md) before planning or synthesis.
2. Capture scope, decision, policy and acceptance criteria in the [discovery brief](templates/discovery-brief.md); separate assumptions from unknowns.
3. Plan interview/persona synthesis or usability test protocols, including audience, accessibility, consent, privacy and authorized evidence access. Missing permission blocks collection/use, not planning.
4. Evaluate supplied artifacts against contracts/standards. Use the [evidence and findings register](templates/evidence-findings.md) to separate observation, interpretation and recommendation; retain locators, confidence, limitations and conflicts.
5. Record non-conformance severity, remediation owners, closure and escalation thresholds. Publish a decision log and restricted handoff with next validation checkpoints.

## Guardrails
- Do not approve out-of-policy changes without documented exception path.
- Do not hide uncertainty in compliance judgments.
- Do not recommend changes without clear ownership and closure criteria.
- Do not conflate style preference with contractual requirement.
- Never fabricate interviews, quotes, metrics, consent, source access or validation.
- Do not contact, record, scrape, publish or transfer data without explicit authorization; keep raw participant data in its approved store.
- Unsupported claims and hypothetical personas remain labeled hypotheses, not findings. Reassess findings when evidence is withdrawn or stale.

## Output
- At the requested downstream destination: discovery brief, research plan/protocol, provenance-linked synthesis/personas, and evidence/findings register.
- Governance report with severity/remediation owners; decision log and handoff with restrictions, assumptions, unknowns and checkpoints. Without evidence, deliver a plan only.

## Delegates / pairs with
- information-architecture
- web-usability-review
- design-bootstrap, design-exploration
- experience-blueprint, wireframing; agent ux-designer
