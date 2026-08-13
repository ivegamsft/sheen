# Component Design Specification Template

Use this template to specify a reusable UI component's design in a Figma-compatible format. Fill in all sections. Leave no section blank — use `N/A` if a section does not apply.

---

## Component Overview

| Field | Value |
|---|---|
| **Component Name** | `<PascalCase name, e.g., ActionButton>` |
| **Category** | `<e.g., Navigation / Input / Feedback / Layout / Data Display>` |
| **Description** | `<one-sentence description of what the component does>` |
| **Design System** | `<name of design system this belongs to, or "standalone">` |
| **Status** | Draft / In Review / Approved / Deprecated |
| **Owner** | `<team or designer name>` |
| **Last Updated** | `YYYY-MM-DD` |

---

## Anatomy

Describe the structural parts of the component. Use an ASCII diagram or labeled list.

```text
+----------------------------------+
| [Icon]  Label Text  [Trailing]   |
+----------------------------------+
```

| Part | Required | Description |
|---|---|---|
| **Icon** (leading) | No | Optional icon before the label |
| **Label** | Yes | Primary text content |
| **Trailing element** | No | Optional trailing icon, badge, or action |
| **Container** | Yes | Bounding box with padding, border, and background |

---

## Variants

Define all variants of the component. Each row is a distinct configuration.

| Variant | Use When | Visual Differences |
|---|---|---|
| **Primary** | Main call to action on the page | `<filled background, high contrast>` |
| **Secondary** | Supporting action | `<outlined, lower emphasis>` |
| **Tertiary** | Low-emphasis or inline action | `<text-only, no border>` |
| **Destructive** | Action that deletes or removes | `<red/danger color scheme>` |

---

## Sizes

| Size | Height | Padding (horizontal) | Font Size | Icon Size | Use When |
|---|---|---|---|---|---|
| **Small** | `<e.g., 32px>` | `<e.g., 12px>` | `<e.g., 14px>` | `<e.g., 16px>` | Dense layouts, tables |
| **Medium** | `<e.g., 40px>` | `<e.g., 16px>` | `<e.g., 16px>` | `<e.g., 20px>` | Default for most contexts |
| **Large** | `<e.g., 48px>` | `<e.g., 20px>` | `<e.g., 18px>` | `<e.g., 24px>` | Touch-primary, hero sections |

---

## Design Tokens

Reference tokens from the design system rather than hard-coded values.

| Property | Token | Value (resolved) |
|---|---|---|
| **Background (default)** | `<e.g., color.action.primary>` | `<e.g., #0066FF>` |
| **Background (hover)** | `<e.g., color.action.primary.hover>` | `<e.g., #0052CC>` |
| **Text color** | `<e.g., color.text.inverse>` | `<e.g., #FFFFFF>` |
| **Border radius** | `<e.g., radius.md>` | `<e.g., 8px>` |
| **Font weight** | `<e.g., font.weight.semibold>` | `<e.g., 600>` |
| **Spacing (internal)** | `<e.g., space.3>` | `<e.g., 12px>` |
| **Focus ring** | `<e.g., color.focus.ring>` | `<e.g., 2px solid #0066FF, 2px offset>` |

---

## States

Define the visual treatment for every interactive state.

| State | Background | Border | Text | Icon | Cursor | Additional |
|---|---|---|---|---|---|---|
| **Default** | `<token>` | `<token>` | `<token>` | `<token>` | pointer | |
| **Hover** | `<token>` | `<token>` | `<token>` | `<token>` | pointer | |
| **Focus** | `<token>` | `<token>` | `<token>` | `<token>` | — | Focus ring visible (WCAG 2.4.7) |
| **Active** | `<token>` | `<token>` | `<token>` | `<token>` | pointer | |
| **Disabled** | `<token>` | `<token>` | `<token>` | `<token>` | not-allowed | Reduced opacity (>= 0.4 for a11y) |
| **Loading** | `<token>` | `<token>` | Hidden | Spinner | wait | `aria-busy="true"` |

---

## Spacing & Layout

| Property | Value | Notes |
|---|---|---|
| **Min width** | `<e.g., 64px>` | Prevents overly narrow instances |
| **Max width** | `<e.g., 100% of parent>` | Label truncates with ellipsis |
| **Margin (external)** | `<e.g., 0 — set by parent layout>` | Component does not own external margin |
| **Gap (icon to label)** | `<e.g., 8px / space.2>` | |
| **Touch target** | `>= 44 x 44 CSS px` | WCAG 2.5.5 (AAA) / best practice for AA |

---

## Interaction Behavior

| Interaction | Behavior |
|---|---|
| **Click / Tap** | `<triggers the primary action>` |
| **Keyboard Enter / Space** | `<triggers the same action as click>` |
| **Tab** | `<moves focus to next focusable element>` |
| **Shift+Tab** | `<moves focus to previous focusable element>` |
| **Escape** | `<N/A unless the component is inside a popover/modal>` |
| **Long press (mobile)** | `<N/A or describe tooltip / context menu>` |

---

## Accessibility

| Requirement | Implementation |
|---|---|
| **Role** | `<e.g., button (native), link, checkbox — use native element when possible>` |
| **Accessible name** | `<visible label, or aria-label for icon-only variants>` |
| **Disabled state** | `aria-disabled="true"` — do not use the `disabled` HTML attribute if you need to convey why |
| **Loading state** | `aria-busy="true"`, `aria-live="polite"` region to announce completion |
| **Focus management** | `<describe any focus trapping or redirection>` |
| **Screen reader announcement** | `<describe what assistive tech announces on interaction>` |
| **Color contrast** | All state combinations meet WCAG 2.1 AA contrast ratios |

---

## Composition / Slots

Define how this component accepts child content or composes with other components.

| Slot | Accepts | Default | Example |
|---|---|---|---|
| **leading** | Icon component | None | `<SearchIcon />` |
| **children / label** | Text or inline elements | Required | `"Save Changes"` |
| **trailing** | Icon, Badge, or Spinner | None | `<ChevronDown />` |

---

## Usage Guidelines

### Do

- Use Primary variant for the single most important action on a screen.
- Provide a visible text label whenever possible — icon-only buttons need `aria-label`.
- Place destructive actions away from primary actions to prevent accidental clicks.

### Don't

- Don't use more than one Primary variant in the same visual group.
- Don't disable buttons without explaining why — use a tooltip or inline message.
- Don't rely on color alone to distinguish variants — ensure shape or text also differs.

---

## Open Questions

| # | Question | Status | Resolution |
|---|---|---|---|
| 1 | `<design question>` | Open / Resolved | `<resolution if resolved>` |
| 2 | `<design question>` | Open / Resolved | `<resolution if resolved>` |
