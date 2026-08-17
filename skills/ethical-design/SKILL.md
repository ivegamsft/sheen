---
name: ethical-design
compatibility: [github-copilot-cli]
description: "Use when detecting dark patterns, coercive UX, deceptive consent flows, or ethically problematic design choices. USE FOR: audit a checkout flow for dark patterns (hidden costs, confirmshaming, roach motel), review a consent UI against GDPR/ISO 29184, detect coercive or manipulative UX patterns, score a design against ethical design principles, recommend ethical alternatives to a problematic pattern. DO NOT USE FOR: legal advice or GDPR compliance certification, backend data processing audits, security penetration testing."
category: development
metadata:
  category: development
  maturity: stable
  audience:
    - developer
    - designer
    - product-manager
allowed-tools: []
---
# Ethical Design Skill

Detect dark patterns, coercive UX, and deceptive consent flows — and recommend ethical alternatives before they ship.

## Closes

GitHub issue #65 — `feat(skill): ethical-design — dark pattern detection, consent UI, deceptive UX audit`

## Dark Pattern Taxonomy

| Pattern | Description | Severity |
|---|---|---|
| Hidden costs | Fees revealed only at checkout | CRITICAL |
| Confirmshaming | "No thanks, I hate saving money" | MAJOR |
| Roach motel | Easy to enter, hard to leave (e.g. subscription cancel) | CRITICAL |
| Misdirection | Visual design draws eye away from important info | MAJOR |
| Disguised ads | Ads styled to look like content | MAJOR |
| Trick questions | Double-negative opt-out pre-checked | CRITICAL |
| Bait and switch | Promise A, deliver B | CRITICAL |
| Privacy zuckering | Complex privacy settings designed to confuse | MAJOR |
| Forced continuity | Silent trial-to-paid upgrade | CRITICAL |
| Friend spam | Address book harvesting disguised as social sharing | CRITICAL |

## Sample Prompts

### Audit a checkout flow

```
@ethical-design audit the checkout wireframe at docs/wireframes/checkout.spec.md
for dark patterns
```

**Output:**
```
## Ethical Design Audit: Checkout

CRITICAL — Hidden costs: Shipping fee appears only on payment screen.
  Recommend: Show total (incl. shipping estimate) from cart onwards.

MAJOR — Misdirection: "Continue as guest" uses low-contrast grey (#9e9e9e on white = 2.85:1).
  Recommend: Equal visual weight for guest vs. account paths.

MAJOR — Confirmshaming: Cancel button reads "No thanks, I'll pay full price".
  Recommend: Neutral label "Cancel" or "Maybe later".

Gate: FAIL (2 critical, 2 major)
```

### Review consent UI

```
@ethical-design review the cookie consent dialog in designs/consent-modal.spec.md
against GDPR Article 7 and ISO 29184
```

### Score against ethical principles

```
@ethical-design score this onboarding flow against ethical design principles
```

### Suggest ethical alternative

```
@ethical-design: our subscription cancel flow requires 3 screens and a phone call.
Suggest an ethical alternative.
```

## Consent UI Checklist (GDPR / ISO 29184)

- [ ] Accept and Reject options have equal visual prominence
- [ ] No pre-checked marketing consent boxes
- [ ] Granular control available (not all-or-nothing)
- [ ] Purpose of each data use is stated in plain language
- [ ] Easy to withdraw consent as it was to give
- [ ] No dark-pattern nudges (smaller reject button, guilt-tripping language)

## Templates in This Skill

| Template | Purpose |
|---|---|
| `ethical-audit-report-template.md` | Structured dark pattern / ethical design audit report |
| `consent-ui-review-template.md` | GDPR/ISO 29184 consent UI compliance review |
| `ethical-alternatives-template.md` | Ethical UX pattern alternatives for common dark patterns |

## Output Schema

```yaml
discriminator: audit-report
scope: page | flow | component
findings:
  - pattern: string
    severity: CRITICAL | MAJOR | MINOR
    location: string
    recommendation: string
consent_compliance: PASS | FAIL | N/A
gate: PASS | WARN | FAIL
critical_count: number
```

## Agent Pairing

- Triggered by: `ux-designer` (pre-ship), `design-reviewer` (PR review)
- Escalates to: `information-architect` (IA restructure for roach-motel patterns)
- Feeds: `brand-steward` (brand integrity when dark patterns harm trust)
- Legal gate: findings flagged CRITICAL should be reviewed by legal before ship
