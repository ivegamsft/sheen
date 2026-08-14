---
# [Component Name] Spec

> Status: Draft | Version: 0.1.0 | Owner: [Team] | Last reviewed: [YYYY-MM-DD]

---

## 1. Overview

**What it is:** [One sentence description of the component's purpose.]

**When to use it:** [Describe the user need this component serves.]

**When not to use it:** [Name alternative components for adjacent use cases.]

**ARIA role:** `[role]` (e.g. `button`, `dialog`, `listbox`, `combobox`)

---

## 2. Anatomy

<!-- Name every sub-element. -->

| Sub-element | Description | Required |
|---|---|---|
| [Root container] | | Yes |
| [Label] | | Yes |
| [Icon] | | No |
| [Indicator] | | Conditional |

---

## 3. Token bindings

| Sub-element | Property | Token | Notes |
|---|---|---|---|
| Root | background | `color.surface` | |
| Root | border | `color.outline` | |
| Root | border-radius | `radius.md` | |
| Label | color | `color.on-surface` | |
| Label | font | `typography.body` | |
| Root (hover) | background | `color.surface.hover` | |
| Root (focus) | outline | `color.primary.focus` | 3:1 contrast required |
| Root (disabled) | background | `color.surface.disabled` | |
| Root (disabled) | opacity | 0.38 | Per M3/Fluent disabled pattern |
| Root (error) | border | `color.error` | |

---

## 4. State matrix

| State | Visual change | Token | ARIA attribute |
|---|---|---|---|
| Default | -- | -- | -- |
| Hover | Background overlay | `color.*.hover` | -- |
| Focus | Outline ring | `color.*.focus` | `:focus-visible` |
| Active / pressed | Background overlay | `color.*.pressed` | `aria-pressed` (toggle only) |
| Selected | Indicator visible | `color.*.selected` | `aria-selected="true"` |
| Disabled | Reduced opacity | `color.*.disabled` | `aria-disabled="true"` |
| Error | Error border + icon | `color.error` | `aria-invalid="true"` |
| Loading | Spinner + text | -- | `aria-busy="true"` |
| Expanded | Chevron rotates | -- | `aria-expanded="true"` |

<!-- Remove inapplicable rows. -->

---

## 5. Keyboard interaction

| Key | Action |
|---|---|
| Tab | Focus the component |
| Shift+Tab | Move focus to previous focusable element |
| Enter / Space | Activate (confirm, open, select) |
| Escape | Dismiss / close (if applicable) |
| Arrow keys | Navigate within composite (if applicable) |
| Home / End | Jump to first / last item (composite) |

**Focus management:**
- On open: focus moves to [first item / input / close button].
- On close: focus returns to the trigger element.
- Focus trap: [Yes / No]. If Yes, describe the trap boundary.

---

## 6. Error state

**Error message format:** "[Name the problem]. [Provide a path to resolution.]"
Example: "Email address is already in use. Sign in or use a different address."

**Implementation:**
- `aria-invalid="true"` on the input.
- `aria-describedby="[error-id]"` on the input pointing to the error message element.
- Error message element: `id="[error-id]"`, `role="alert"` or `aria-live="assertive"`.
- Do not expose system internals in the error message.

---

## 7. Empty state (if applicable)

**Empty state message:** "[Explain what the space is for.] [Provide one actionable step.]"

---

## 8. Reduced motion

| Animation | Default behavior | Reduced motion behavior |
|---|---|---|
| [Entry animation] | [Duration + easing] | [Static / instant / opacity-only] |
| [State transition] | [Duration + easing] | [Instant swap] |

---

## 9. Accessibility summary

- **WCAG level:** 2.2 AA
- **ARIA role:** `[role]`
- **Required ARIA attributes:** [list]
- **Keyboard pattern:** [APG pattern name and link]
- **Screen reader tested:** [Yes / No / Pending] with [VoiceOver / NVDA / JAWS]
- **High-contrast theme:** [Tested / Pending]

---

## 10. Usage examples

<!-- Code or Figma embed. -->

---

## 11. Do / Don't

| Do | Don't |
|---|---|
| [Correct usage] | [Incorrect usage] |
