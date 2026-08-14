---
name: sheen-50-brand-voice
compatibility: [github-copilot-cli]
description: "Always-on brand identity constraints: voice, logo, color, typography, and imagery."
applyTo: "**/*"
metadata:
  band: 50
  layer: brand
---

# Brand Voice and Identity

Apply these constraints when producing copy, reviewing visual design, specifying
tokens, or auditing brand compliance. They distill the `brand.github.com` identity
system into ambient rules for sheen skills and agents.

## Voice principles

sheen assets communicate in the voice of the brand they govern. Default voice
rules (apply unless overridden by a consumer's brand guide):

- **Clear over clever:** say what you mean without wordplay that obscures meaning.
- **Concise:** every word earns its place. Remove filler, hedges, and redundancy.
- **Genuine:** avoid hype, superlatives, and marketing inflation ("revolutionary",
  "world-class", "amazing"). State facts and let them speak.
- **Warm but not casual:** professional and approachable. Avoid slang that
  excludes non-native speakers. Avoid stiffness that creates distance.
- **Inclusive:** use language that includes all users. Prefer gender-neutral
  pronouns and terms. Avoid idioms that do not translate well.
- **Active voice:** "Save your work" not "Your work can be saved." Exceptions
  exist for legal and procedural copy.

## Tone modulation

Voice is consistent; tone adapts to context:

| Context | Tone |
|---|---|
| Onboarding / empty state | Encouraging, clear, brief. "Let's get started" not "No data found." |
| Error state | Direct, non-blaming, actionable. Name the problem and the fix. Never apologize for system failures with hollow phrases. |
| Confirmation / success | Affirming and brief. Avoid excessive celebration for routine tasks. |
| Destructive action warning | Precise and serious. Name exactly what will be deleted or lost. |
| Help and documentation | Instructive and task-focused. Numbered steps. Active imperative verbs. |

## Logo and brand mark rules

- Do not alter, recolor, rotate, or distort the brand mark.
- Maintain the minimum clear space (defined by the brand guide; default: the cap
  height of the mark on all sides).
- Do not place the mark on busy backgrounds or colors that violate contrast rules.
- Do not use the mark as a bullet point, decorative element, or watermark.

## Color constraints

- Brand colors are defined as core tokens; do not introduce ad-hoc hex values.
- Primary brand color usage must not violate WCAG 2.2 AA contrast when paired with
  any foreground color defined in the token system.
- Do not use brand color for error states (reserve red/error-signal colors for
  error semantic tokens, not brand tokens).
- Dark mode and high-contrast equivalents are required for every brand color used
  in a semantic role.

## Typography constraints

- Use only type families defined in the token system (`typography.*` tokens).
- Type scale steps are tokens; do not hardcode `font-size` or `line-height` values.
- Maintain a clear hierarchy: one primary heading level per page or screen section.
- Minimum body text size: 16 px equivalent (1 rem). Do not go below 12 px for
  any visible text (including captions and legal copy).
- Line length: 45-75 characters per line for body text (readability optimum).

## Imagery and illustration rules

- Imagery must reinforce the message, not decorate for its own sake.
- Provide meaningful alt text for every non-decorative image. Decorative images
  use `alt=""` and `aria-hidden="true"`.
- Illustration style must be consistent within a product surface. Mixing
  illustration styles in the same view is a brand violation.
- Photography and illustration must represent diverse subjects and contexts.

## Review lens

Before finalizing any copy or visual recommendation, ask:

- Is the language clear, concise, genuine, and inclusive?
- Is tone appropriate to the context (error, success, onboarding)?
- Does the brand mark appear unaltered with adequate clear space?
- Are all colors referencing semantic tokens (not ad-hoc hex values)?
- Does every non-decorative image have meaningful alt text?
- Are typography sizes and families from the token system?
