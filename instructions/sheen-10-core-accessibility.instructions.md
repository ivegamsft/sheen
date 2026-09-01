---
name: sheen-10-core-accessibility
compatibility: [github-copilot-cli]
description: "Path-scoped accessibility baseline: WCAG 2.2 AA and WAI-ARIA rules for design and UI surfaces."
applyTo: "**/*.html,**/*.css,**/*.scss,**/*.sass,**/*.less,**/*.styl,**/*.jsx,**/*.tsx,**/*.vue,**/*.svelte,**/*.astro,**/*.md,**/*.mdx,**/*.svg,**/components/**,**/ui/**,**/frontend/**,**/client/**,**/web/**,**/design/**,**/docs/**,**/tokens/**"
metadata:
  band: 10
  layer: core
---

# Core Accessibility Baseline

Apply these rules to every sheen design asset, skill output, and recommendation.
Accessibility is not an end-of-project checklist; it is a foundation that shapes
every token, component, and content decision.

## Conformance target

The mandatory floor is **WCAG 2.2 Level AA**. EN 301 549 / Section 508 / ADA
conformance is satisfied by meeting WCAG 2.2 AA. Aspirational target is AAA where
feasible. WCAG 3 and the APCA contrast algorithm are in draft; track but do not
gate on them until referenced by law or procurement.

## The four POUR principles

| Principle | What it means for design |
|---|---|
| **Perceivable** | No content is color-only, audio-only, or vision-only without an equivalent alternative. |
| **Operable** | All functionality is reachable and triggerable without a mouse. No time limits trap keyboard users. |
| **Understandable** | Language, behavior, and error messages are clear. Form inputs have labels; errors name the problem and the fix. |
| **Robust** | Markup is valid and interpreted consistently by assistive technology (screen readers, switch access, magnification). |

## Non-negotiable rules

- **Contrast (text):** 4.5:1 normal text; 3:1 large text (>=18 pt / 14 pt bold).
  Enforced as a `checks.json` hard error gate.
- **Contrast (non-text):** UI components and focus indicators must meet 3:1 against
  adjacent colors.
- **Color is never the only signal:** status, category, or state conveyed by color
  must also be conveyed by text, pattern, or icon.
- **Keyboard reachability:** every interactive element is reachable via Tab and
  operable via keyboard (Enter/Space to activate; arrow keys for composites).
- **Visible focus indicator:** never suppress `outline` without an equivalent custom
  indicator meeting 3:1 contrast.
- **Touch targets >= 44 x 44 CSS px** (WCAG 2.5.5 AAA target; 24 x 24 minimum).
- **All states defined accessibly:** default, hover, focus, active, disabled, error,
  loading, and selected states must each be specified with their accessible behavior.
- **Descriptive error messages:** name the problem and a fix ("Password must be at
  least 8 characters"), not just a flag ("Invalid input").

## WAI-ARIA requirements

Apply WAI-ARIA 1.2 and the ARIA Authoring Practices Guide (APG):

- Use semantic HTML first. ARIA supplements; it does not replace native roles.
- Every interactive widget that is not a native HTML element must declare: `role`,
  relevant `aria-*` states, and `aria-label` / `aria-labelledby` when the visible
  label is absent or insufficient.
- Modal dialogs must trap focus and restore it to the trigger on close.
- Dynamic content updates (toasts, progress, inline validation) must use
  `aria-live` regions.

## High-contrast theme

sheen's token system includes `tokens/themes/high-contrast`. Every component spec
must be tested against the high-contrast theme in addition to light and dark.

## Reduced motion

Respect `prefers-reduced-motion`. Motion token recommendations must include a
reduced-motion variant. Never use motion as the sole signal of state change.

## Output requirements

Every asset produced by a sheen skill or agent must include an accessibility
section naming: WCAG level, relevant success criteria, keyboard interaction model,
and ARIA role/state mapping where applicable.

## Review lens

Before finalizing any recommendation, ask:

- Does every color pair meet the WCAG contrast threshold?
- Is color the only signal for any piece of information?
- Can a keyboard user reach and operate every interactive element?
- Is every interactive element's ARIA role, state, and keyboard model specified?
- Are all component states defined accessibly?
- Is there a reduced-motion variant for any animation?
