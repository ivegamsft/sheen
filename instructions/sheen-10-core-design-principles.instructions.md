---
name: sheen-10-core-design-principles
compatibility: [github-copilot-cli]
description: "Path-scoped design values and craft principles for design assets, UI surfaces, and reviews."
applyTo: "**/*.html,**/*.css,**/*.scss,**/*.sass,**/*.less,**/*.styl,**/*.jsx,**/*.tsx,**/*.vue,**/*.svelte,**/*.astro,**/*.md,**/*.mdx,**/*.svg,**/components/**,**/ui/**,**/frontend/**,**/client/**,**/web/**,**/design/**,**/docs/**,**/tokens/**,**/assets/**,**/public/**"
metadata:
  band: 10
  layer: core
---

# Core Design Principles

Apply these values to every design decision, review, and audit sheen performs. They
are not checkboxes -- they are lenses. Use them to justify recommendations, weigh
tradeoffs, and resolve debates.

## Design values

sheen adopts the following named values, drawn from Windows 11 and Material 3, so
every skill and agent appeals to a shared vocabulary rather than subjective taste.

| Value | In practice |
|---|---|
| **Effortless** | The obvious path is the easy path. Reduce steps, choices, and cognitive load. Prefer progressive disclosure over upfront complexity. |
| **Calm** | Quiet by default. Motion, color, and density serve the task, not decoration. Reserve emphasis for what matters. |
| **Personal** | Respect user context: locale, accessibility settings, platform, preference. Do not design only for the majority case. |
| **Familiar** | Reuse established patterns and platform conventions. Minimize surprise. Deviation must justify itself. |
| **Complete + Coherent** | Cover the full journey: empty state, loading state, error state, success state. One system, one voice, one motion language. |

## Craft bar

The `impeccable` inspiration source sets the aesthetic bar: a design is right when
it is **invisible** -- when it feels inevitable rather than designed. Apply this
standard to every spacing decision, typographic hierarchy, and color pairing.

## How to use these values in reviews

When evaluating a design, token set, or component spec, test it against each value:

- **Effortless:** Is the task path shorter than any reasonable alternative? Is every
  step necessary?
- **Calm:** Does the page or component draw attention to itself, or does it serve the
  user's goal? Is motion purposeful?
- **Personal:** Does this work for keyboard-only users? For right-to-left locales?
  For users with reduced motion or low-vision preferences?
- **Familiar:** Would a user already knowing the platform recognize these patterns?
  What convention is being broken, and is the deviation worth the cost?
- **Complete + Coherent:** Are all states defined (empty, error, loading, success)?
  Do component behaviors and token scales agree across the system?

## Tradeoff resolution

When two values conflict -- for example, a richer, more Personal experience that
adds cognitive load -- resolve in favor of **Effortless** and **Familiar** by
default, because the majority of users encounter the default path. Document the
tradeoff explicitly in an ADR or design-debate output.

## Voice of craft

When writing recommendations or reviews:

- Name the value being violated or upheld ("This violates **Calm** by introducing
  motion that does not serve the task").
- Prefer specific, actionable language over vague quality terms (nice, clean, better).
  Anchor every judgment to a named value or measurable standard.

## Relationship to other instructions

- `sheen-10-core-accessibility` makes the **Personal** value formal and testable.
- `sheen-40-web-usability` applies **Effortless** and **Familiar** via NN/g heuristics.
- `sheen-50-brand-voice` governs how **Calm** and **Personal** are expressed in copy and tone.
- `sheen-90-standards-conformance` sets the legally non-negotiable floor beneath all values.

## Review lens

Before finalizing any recommendation, ask:

- Have I tested this against all five values?
- Have I named which value my recommendation serves?
- Have I covered all states (empty, error, loading, success)?
- Am I enforcing personal taste, or appealing to a named value?
- Would a keyboard-only, RTL, or low-vision user experience this differently?
