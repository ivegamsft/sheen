---
name: craft-quality
compatibility: [github-copilot-cli]
description: "Use when running a craft and polish pass to assess consistency, refinement, and visual quality. USE FOR: craft checklist passes, polish quality assessments, consistency refinements. DO NOT USE FOR: formal usability audits, framework detection scans."
category: governance
metadata:
  category: governance
  maturity: stable
  audience: [designer, developer]
  pillar: governance
allowed-tools: []
---

# craft-quality

Apply craft-quality standards with actionable findings.

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
- Do not mandate a specific typeface, measurement, or visual treatment when
  reviewing typography or structural devices.

## Output
- Governance report with findings, severity, and remediation owners.
- Decision log with follow-up checkpoints.

## Delegates / pairs with
- design-review
- design-debate

## Typography & Structural-Semantic Review (#183)

Extends the craft pass with a practical review of type as an active
hierarchy tool and of structural devices as information carriers, not
decoration:

- **Measure & rhythm.** Check reading line length and line-height are
  appropriate to the content and the type's own characteristics (x-height,
  weight); flag lines that are uncomfortably long/short or too tight/loose
  to read at pace.
- **Role & hierarchy.** Confirm distinct type roles (heading, body, caption,
  label, etc.) are separated by scale, weight, width, and spacing — not
  color alone — and that the resulting hierarchy matches content priority.
- **Display intentionality.** Display/hero typography must contribute an
  intentional effect (emphasis, pacing, wayfinding); flag display type used
  by default with no stated purpose.
- **Structural-semantic purpose test.** For every label, border, divider,
  numbering, or outline treatment, ask "what would a user lose if this were
  removed?" It must encode hierarchy, sequence, grouping, state, or
  affordance to pass.
- **Decorative-only flag.** Any structural device that fails the purpose
  test is flagged with an actionable alternative — remove it, or replace it
  with a device that does carry the missing information.
- **Downstream constraints.** Verify token, brand, accessibility (contrast,
  zoom/reflow), localization (text expansion), and responsive behavior are
  respected as given constraints, not re-litigated here.
- **Finding separation.** Report system-contract violations (token, brand,
  or accessibility breaches) separately from subjective craft
  recommendations so remediation urgency and ownership stay unambiguous.

These checks are implementation-neutral: they never mandate a specific
typeface, measurement, or visual treatment.
