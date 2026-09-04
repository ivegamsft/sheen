---
name: design-review
compatibility: [github-copilot-cli]
description: "Use when critiquing a design artifact against principles, craft standards, or system guidelines. USE FOR: artifact critique, principle-based review, craft issue identification. DO NOT USE FOR: multi-option debate facilitation, full repo audits."
category: governance
metadata:
  category: governance
  maturity: stable
  audience: [designer, developer]
  pillar: governance
allowed-tools: []
---

# design-review

Run craft-bar reviews for a single artifact or flow.

## Workflow
1. Define governed scope, policy expectations, and acceptance criteria.
2. Evaluate artifacts against explicit contracts and standards.
3. Record non-conformance findings with severity and remediation path.
4. Recommend policy-safe improvements with escalation thresholds.
5. Publish a concise decision log for review and auditability.

## Guardrails
- Do not approve out-of-policy changes without documented exception path.
- Do not hide uncertainty in compliance judgments.
- Do not recommend changes without clear ownership and closure criteria.
- Do not conflate style preference with contractual requirement.
- Do not review generic placeholder content alone when representative
  content is available.
- Do not perform more than one revision pass inside this workflow; escalate
  further concerns instead of looping indefinitely.

## Output
- Governance report with findings, severity, and remediation owners.
- Decision log with follow-up checkpoints.

## Delegates / pairs with
- craft-quality
- web-usability-review
- visual-regression

## Real-Content Calibration & Visual Self-Critique Loop (#185)

A bounded, evidence-led loop that runs before an artifact is considered
review-complete:

1. **Representative content.** Use domain-representative content and
   realistic data shapes wherever available (real or realistic sample copy,
   actual field lengths, plausible record counts) instead of generic
   placeholder/lorem-ipsum content alone.
2. **Mark invented content.** Explicitly label any invented copy, data, or
   assumption so reviewers know what is illustrative versus sourced.
3. **Exercise state extremes.** As applicable, exercise short, long, empty,
   error, loading, partial, permission-restricted, and localized content
   conditions.
4. **Capture rendered evidence when available.** Render the artifact and
   capture a screenshot/visual snapshot when the environment supports it
   (for example via the `visual-regression` skill's Playwright pipeline, or
   any other available rendering path) — no specific tool, framework, or
   screenshot service is mandated.
5. **Critique the evidence.** Assess hierarchy, readability, density,
   alignment, focal competition, overflow, responsive behavior, and
   unnecessary decoration.
6. **One focused revision pass.** Make one bounded round of revisions
   targeting the highest-impact findings, and record what changed and why.
7. **Tool-neutral fallback.** When rendering or screenshots are unavailable,
   perform the same critique (step 5) against the structural/markup/spec
   representation instead, and state explicitly that the fallback path was
   used.

**Stopping rule.** The loop is complete once (a) representative content and
applicable state extremes have been exercised or explicitly marked
not-applicable, (b) one critique pass has been recorded against rendered
evidence or its documented fallback, and (c) exactly one revision pass has
been made and recorded — do not iterate further rounds inside this
workflow; escalate remaining concerns to a follow-up review.
