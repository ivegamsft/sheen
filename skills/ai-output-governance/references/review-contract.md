# AI Output Review Contract (#64)

Read before reviewing any AI content. Apply every relevant dimension and
the output schema below; sample prompts illustrate copy, imagery, component,
and pre-production reviews. Example paths refer to the downstream project.

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
Representational:  ⚠️  CRITICAL — "users who struggle with technology" is exclusionary.
                       Recommend: "users new to [product]"
Brand safety:      ✅ Tone matches brand-guide.md (friendly, direct)
Accessibility:     ✅ No image alt text required for text-only copy
Content moderation:✅ No harmful content detected
Disclosure:        ⚠️  MAJOR — policy requires "AI-assisted" label on generated bios.

Gate: FAIL (1 critical, 1 major)
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

## Report artifact roles

These are suggested downstream artifact names, not bundled template files.
Create them using the dimensions and schema in this reference.

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

## Policy sources

Read the downstream project's `docs/brand/brand-guide.md` and
`docs/decisions/ai-content-policy.md` (or its supplied equivalents).
These are consumer inputs, not files bundled with this skill; record missing policy.
