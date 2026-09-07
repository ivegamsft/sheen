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
| Accessibility | Images require appropriate text alternatives; ordinary text needs no image alt attributes; components require appropriate accessibility behavior | MAJOR |
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
Image alternatives: N/A — text-only copy contains no images; image alt attributes do not apply.
Other accessibility: UNKNOWN — rendered context not supplied; no WCAG approval claimed.
Content moderation:✅ No harmful content detected
Disclosure:        ⚠️  MAJOR — policy requires "AI-assisted" label on generated bios.

Gate: FAIL (1 critical, 1 major)
```

Use N/A only for an inapplicable check, with the reason. Missing evidence is
UNKNOWN, not N/A or PASS; request the evidence and leave that check unresolved.
An image-alternative N/A does not approve other accessibility checks or WCAG
conformance. Apply relevant text checks and component behavior checks separately.

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
dimension_results:
  - dimension: string
    status: PASS | FAIL | N/A | UNKNOWN
    reason: string
    evidence_refs: [string]
findings:
  - dimension: string
    severity: CRITICAL | MAJOR | MINOR | INFO
    finding: string
    recommendation: string
summary:
  critical: number
  major: number
gate: PASS | WARN | FAIL | UNRESOLVED
```

Each evaluated dimension has a result; only confirmed failures create
severity-bearing findings. N/A and UNKNOWN require reasons; record available
evidence references and identify what is missing. They are not passing results
and do not add to severity counts. Every finding must match a FAIL dimension.

Gate precedence: any confirmed CRITICAL finding means FAIL, even with unknown
checks. Otherwise any UNKNOWN check, or no applicable checks, means UNRESOLVED.
With complete applicable evidence, MAJOR findings mean WARN; otherwise PASS.
UNRESOLVED is non-approving and requests evidence, not a fabricated violation.
Consumers must handle the new result and gate states explicitly.

### Gate decision examples

These rows isolate gate logic; they do not replace per-dimension reasons or
evidence. The illustrative failures below are CRITICAL or MAJOR only.

| Check statuses | Critical | Major | Gate |
|---|---:|---:|---|
| UNKNOWN | 0 | 0 | UNRESOLVED |
| FAIL, UNKNOWN | 1 | 0 | FAIL |
| FAIL, UNKNOWN | 0 | 1 | UNRESOLVED |
| FAIL | 0 | 1 | WARN |
| PASS, N/A | 0 | 0 | PASS |
| N/A | 0 | 0 | UNRESOLVED |
| PASS | 0 | 0 | PASS |

## Policy sources

Read the downstream project's `docs/brand/brand-guide.md` and
`docs/decisions/ai-content-policy.md` (or its supplied equivalents).
These are consumer inputs, not files bundled with this skill; record missing policy.
