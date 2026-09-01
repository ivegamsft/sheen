---
name: sheen-30-components-states
compatibility: [github-copilot-cli]
description: "Path-scoped rules for component anatomy, interaction states, ARIA mapping, and keyboard models."
applyTo: "**/*.html,**/*.css,**/*.scss,**/*.sass,**/*.less,**/*.styl,**/*.jsx,**/*.tsx,**/*.vue,**/*.svelte,**/*.astro,**/*.md,**/*.mdx,**/components/**,**/ui/**,**/frontend/**,**/client/**,**/web/**,**/design/**,**/docs/components/**,**/tokens/**"
metadata:
  band: 30
  layer: components
---

# Component Anatomy, States, and Interaction

Apply these rules when specifying, reviewing, or auditing any component in a
design system. They implement WAI-ARIA 1.2 APG patterns and the token state model.

## Every component specification must include

1. **Name and role:** the component name, its HTML element or ARIA `role`, and its
   position in the interaction model (control, container, overlay, composite).
2. **Anatomy:** a named list of sub-elements (trigger, label, icon, indicator,
   container, overlay, list item, etc.) and their token bindings.
3. **State matrix:** every state the component can be in, the token values for each,
   and the ARIA attribute that signals it.
4. **Keyboard interaction:** the full keyboard model per the ARIA APG pattern
   (Tab to reach, Enter/Space to activate, arrow keys for composites, Escape to
   dismiss).
5. **Focus management:** where focus goes on open, on close, and on selection.
6. **Error and empty states:** what the component looks and reads as when in an
   error or empty condition.
7. **Reduced motion variant:** what animations or transitions are replaced or
   removed at `prefers-reduced-motion: reduce`.

## Required states

Every interactive component must define all applicable states:

| State | Token suffix | ARIA signal |
|---|---|---|
| Default | (base) | -- |
| Hover | `.hover` | -- (CSS only) |
| Focus | `.focus` | `:focus-visible` + visible indicator |
| Active / pressed | `.pressed` | `aria-pressed` (toggle) |
| Selected | `.selected` | `aria-selected` |
| Checked | `.checked` | `aria-checked` |
| Disabled | `.disabled` | `aria-disabled="true"` (prefer over HTML `disabled`) |
| Error | `.error` | `aria-invalid="true"` + `aria-describedby` pointing to error text |
| Loading | `.loading` | `aria-busy="true"` + live region for completion |
| Expanded | `.expanded` | `aria-expanded` |

Omitting a required state is a `checks.json` advisory warning.

## Composite widget keyboard patterns (ARIA APG)

| Widget | Pattern |
|---|---|
| Menu / dropdown | Arrow keys navigate; Enter/Space select; Escape dismiss; focus returns to trigger |
| Tabs | Arrow keys switch tabs; Tab moves into panel; Shift+Tab back to tab list |
| Dialog / modal | Focus traps inside; Escape closes; focus returns to trigger |
| Combobox | Arrow keys navigate listbox; Enter selects; Escape closes; typing filters |
| Slider | Arrow keys adjust value; Home/End jump to min/max |
| Tree / treegrid | Arrow keys navigate; Enter opens/closes node; Space selects |
| Listbox | Arrow keys navigate; Enter/Space select; Shift+click extends selection |

Always refer to the full ARIA APG pattern for the widget type; the table above is
a quick reference, not a substitute.

## Token bindings

Component anatomy tokens follow the semantic tier naming:

- Background: `color.surface` (container), `color.primary` (brand-filled)
- Text: `color.on-surface`, `color.on-primary`
- Border: `color.outline`, `color.outline-variant`
- State overlays: semantic state tokens (e.g. `color.primary.hover`) applied as
  overlay or direct value swap
- Radius: `radius.*` token (not hardcoded px)
- Elevation: `elevation.*` token (shadow level)
- Motion: `motion.duration.*` and `motion.easing.*` (never hardcoded ms or
  cubic-bezier)

## Error states

Error messages in components must:

- Name the problem ("Email address is required").
- Provide a path to resolution ("Enter a valid email address").
- Not reveal system internals (no stack traces, DB errors, or internal IDs).
- Be associated with the input via `aria-describedby`.

## Review lens

Before finalizing any component spec, ask:

- Are all required states defined with their token bindings and ARIA attributes?
- Is the keyboard interaction model complete and tested against the ARIA APG pattern?
- Is focus management specified for open, close, and selection?
- Does the error state name the problem and the fix without leaking system internals?
- Is a reduced-motion variant defined for any animation?
- Are all token bindings referencing semantic tokens (not core or hardcoded values)?
