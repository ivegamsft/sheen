---
name: ai-output-governance
compatibility: [github-copilot-cli]
description: "Use when reviewing AI-generated UI copy, imagery, or components for bias, hallucination, brand safety, and accessibility compliance. USE FOR: audit AI-generated copy for harmful bias or hallucinated facts, review AI-generated images for brand compliance and representational fairness, flag AI-generated UI components that violate accessibility or token standards, enforce content moderation thresholds before AI output reaches users. DO NOT USE FOR: implementing AI model inference, training data curation, backend ML pipeline design."
category: development
metadata:
  category: development
  maturity: stable
  audience:
    - developer
    - designer
    - content-author
allowed-tools: []
---
# AI Output Governance Skill

Review AI-generated content (copy, imagery, UI components) before it reaches users — catching bias, hallucination, brand deviation, and accessibility violations at the design gate.

## Closes

GitHub issue #64 — `feat(skill): ai-output-governance — review AI-generated copy, imagery, and UI for bias, hallucination, brand safety`

## Review Dimensions

| Dimension | Check | Severity on Fail |
|---|---|---|
| Factual accuracy | Claims match cited sources; no hallucinated data | CRITICAL |
| Representational fairness | No stereotyped, exclusionary, or marginalised depictions | CRITICAL |
| Brand safety | Tone, terminology, and imagery match brand guide | MAJOR |
| Accessibility | AI copy has alt text; AI images have meaningful descriptions | MAJOR |
| Token compliance | AI-generated UI uses design system tokens, not hardcoded values | MAJOR |
| Content moderation | No harmful, explicit, or legally risky content | CRITICAL |
| Disclosure | AI-generated content labelled where required by policy | MAJOR |

## Sample Prompts

### Review AI-generated copy

```
@ai-output-governance review this AI-generated onboarding copy for bias,
hallucination, and brand safety:
[paste copy here]
```

**Output:**
```
## AI Copy Review

Factual accuracy:  ✅ No hallucinated claims detected
Representational:  ⚠️  MAJOR — "users who struggle with technology" is exclusionary.
                       Recommend: "users new to [product]"
Brand safety:      ✅ Tone matches brand-guide.md (friendly, direct)
Accessibility:     ✅ No image alt text required for text-only copy
Content moderation:✅ No harmful content detected
Disclosure:        ⚠️  MAJOR — policy requires "AI-assisted" label on generated bios.

Gate: WARN (0 critical, 2 major)
```

### Review AI-generated imagery

```
@ai-output-governance review the AI-generated hero images in designs/hero-v2/
for representational fairness and brand compliance
```

### Audit AI-generated component

```
@ai-output-governance audit this AI-generated React component for
token compliance and accessibility violations:
[paste component code]
```

### Enforce pre-production gate

```
@ai-output-governance run the full AI output governance gate on
all content in docs/ai-generated/ before the sprint-3 release
```

## Templates in This Skill

| Template | Purpose |
|---|---|
| `ai-content-review-template.md` | Structured review report for AI-generated copy or imagery |
| `ai-component-audit-template.md` | AI-generated UI component audit against token + a11y standards |
| `ai-disclosure-checklist.md` | Disclosure labelling compliance checklist |

## Output Schema

```yaml
discriminator: audit-report
content_type: copy | imagery | component | mixed
dimensions_reviewed: [string]
findings:
  - dimension: string
    severity: CRITICAL | MAJOR | MINOR | INFO
    finding: string
    recommendation: string
summary:
  critical: number
  major: number
gate: PASS | WARN | FAIL
```

## Agent Pairing

- Triggered by: `brand-steward` (brand safety), `accessibility-auditor` (a11y on AI content)
- Feeds: `ux-designer` (revise copy/imagery), `design-reviewer` (final visual QA)
- Policy source: `docs/brand/brand-guide.md`, `docs/decisions/ai-content-policy.md`
