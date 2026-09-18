---
name: ethical-design
compatibility: [github-copilot-cli]
description: "Use when detecting dark patterns, coercive UX, deceptive consent flows, or ethically problematic design choices. USE FOR: audit a checkout flow for dark patterns (hidden costs, confirmshaming, roach motel), review a consent UI against GDPR/ISO 29184, detect coercive or manipulative UX patterns, score a design against ethical design principles, recommend ethical alternatives to a problematic pattern. DO NOT USE FOR: legal advice or GDPR compliance certification, backend data processing audits, security penetration testing."
category: governance
metadata:
  category: governance
  maturity: stable
  audience:
    - developer
    - designer
    - product-manager
  pillar: governance
allowed-tools: []
---
# Ethical Design Skill

Detect dark patterns, coercive UX, and deceptive consent; recommend ethical alternatives before ship.

## Workflow

1. Scope the page, flow, or component and collect design/content evidence.
2. Read and apply the [ethics contract](references/ethics-contract.md): ten-pattern taxonomy/severities, scenarios, consent checklist, artifact roles, and schema.
3. Audit checkout, onboarding, consent, and cancellation as applicable; locate findings and propose non-coercive alternatives.
4. Record consent status, critical count, and PASS/WARN/FAIL gate; escalate critical findings for legal review before ship.

## Guardrails

- Equal Accept/Reject prominence; no prechecked marketing consent, guilt nudges, or disguised choices.
- Require granular controls, plain-language purposes, and withdrawal as easy as consent.
- Preserve the taxonomy's CRITICAL/MAJOR severities; legal should review CRITICAL findings before ship.
- This is design review, not legal advice, GDPR certification, backend processing audit, or penetration testing.

## Output

- Downstream ethical audit, consent UI review, and ethical alternatives.
- Reference `audit-report` schema: scope, pattern/severity/location/recommendation findings, consent PASS/FAIL/N/A, gate, critical count.

## Delegates / pairs with

- Triggered by: `ux-designer` (pre-ship), `design-reviewer` (PR).
- Escalates: `information-architect` (roach-motel IA restructuring).
- Feeds: `brand-steward` (trust/brand integrity); legal reviews critical findings.
