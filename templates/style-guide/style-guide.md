---
# [Product Name] Style Guide

> Version: 0.1.0 | Owner: [Team Name] | Last updated: [YYYY-MM-DD]
>
> This style guide governs the visual language, voice, and interaction patterns of
> [Product Name]. It is maintained by [Team Name] and reviewed quarterly.
> Questions: open an issue tagged `style-guide`.

---

## 1. Design values

<!-- List the product's named design values. Use the sheen design-context values as
a starting point and adapt to your product's context. -->

| Value | What it means for [Product Name] |
|---|---|
| Effortless | |
| Calm | |
| Personal | |
| Familiar | |
| Complete + Coherent | |

---

## 2. Color

<!-- Reference the token system. Do not paste hex values here; link to token files. -->

| Role | Token | Light value | Dark value | High-contrast |
|---|---|---|---|---|
| Surface | `color.surface` | | | |
| Primary | `color.primary` | | | |
| On primary | `color.on-primary` | | | |
| Error | `color.error` | | | |

**Contrast compliance:** all color pairings in the table above must meet WCAG 2.2
AA (4.5:1 text, 3:1 non-text). Run `color-contrast-check` to validate.

---

## 3. Typography

| Role | Token | Family | Size | Weight | Line height |
|---|---|---|---|---|---|
| Display | `typography.display` | | | | |
| Heading 1 | `typography.heading-1` | | | | |
| Body | `typography.body` | | | | |
| Caption | `typography.caption` | | | | |
| Code | `typography.code` | | | | |

---

## 4. Spacing and layout

| Token | Value | Use |
|---|---|---|
| `space.1` | | Tight: between label and input |
| `space.2` | | Default: between related elements |
| `space.4` | | Loose: between sections |
| `space.8` | | Section margins |

Grid: [columns] columns at [breakpoint]; [columns] columns below [breakpoint].

---

## 5. Voice and tone

**Voice (constant):** [Describe the product's voice in 2-3 sentences.]

**Tone by context:**

| Context | Tone | Example |
|---|---|---|
| Onboarding | | |
| Error | | |
| Success | | |
| Destructive action | | |

---

## 6. Iconography

<!-- Reference the icon set and usage rules. -->

- Icon library: [Name + version]
- Icon sizes: [list token sizes]
- Decorative icons: `aria-hidden="true"`
- Meaningful icons: `aria-label="[description]"` or paired with visible text

---

## 7. Motion

| Purpose | Duration token | Easing token | Notes |
|---|---|---|---|
| Micro-interaction | `motion.duration.fast` | `motion.easing.standard` | Button feedback, checkbox |
| Page transition | `motion.duration.medium` | `motion.easing.emphasized` | Route change |
| Overlay entry | `motion.duration.medium` | `motion.easing.decelerate` | Modal, drawer open |

All animations must have a `prefers-reduced-motion: reduce` variant that eliminates
or substitutes static transitions.

---

## 8. Accessibility

- **WCAG level:** 2.2 AA (mandatory)
- **Color contrast:** validated via `color-contrast-check` skill
- **Keyboard:** all interactive elements reachable and operable via keyboard
- **Screen reader:** tested with [VoiceOver / NVDA / JAWS]
- **Reduced motion:** all animations respect `prefers-reduced-motion`

---

## 9. Component index

<!-- Link to individual component specs. -->

| Component | Spec | Status |
|---|---|---|
| Button | [link] | Draft |
| Input | [link] | Draft |
| Modal | [link] | Draft |

---

## 10. Changelog

| Version | Date | Change |
|---|---|---|
| 0.1.0 | [YYYY-MM-DD] | Initial draft |
