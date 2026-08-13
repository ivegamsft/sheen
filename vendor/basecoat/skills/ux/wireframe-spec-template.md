# Wireframe Specification Template

Use this template to specify the layout, content hierarchy, and interaction behavior for a screen or view. Fill in all sections. Leave no section blank — use `N/A` if a section does not apply.

---

## Screen Overview

| Field | Value |
|---|---|
| **Screen Name** | `<descriptive name>` |
| **Route / URL** | `<e.g., /dashboard, /settings/profile>` |
| **Purpose** | `<what the user accomplishes on this screen>` |
| **Parent Flow** | `<user journey or feature this belongs to>` |
| **Platform** | Web / Mobile / Desktop / Responsive |
| **Owner** | `<team or designer name>` |
| **Last Updated** | `YYYY-MM-DD` |

---

## Layout Structure

Define the major layout regions. Use ASCII art or a description grid.

```
+-------------------------------------------+
|                 Header                    |
+----------+--------------------------------+
|          |                                |
|  Sidebar |         Main Content           |
|  (nav)   |                                |
|          |                                |
+----------+--------------------------------+
|                 Footer                    |
+-------------------------------------------+
```

_Replace with the actual layout for this screen._

### Responsive Behavior

| Breakpoint | Layout Changes |
|---|---|
| **Desktop (> 1024px)** | `<default layout — describe column structure>` |
| **Tablet (641–1024px)** | `<what collapses, stacks, or reflows>` |
| **Mobile (<= 640px)** | `<single-column behavior, hamburger nav, bottom sheet, etc.>` |

---

## Content Hierarchy

List content elements in priority order (most important first). This drives both visual hierarchy and screen reader order.

| Priority | Element | Type | Required | Notes |
|---|---|---|---|---|
| 1 | `<e.g., Page title>` | Heading (h1) | Yes | `<additional context>` |
| 2 | `<e.g., Summary stats>` | Data display | Yes | `<additional context>` |
| 3 | `<e.g., Action buttons>` | Interactive | Yes | `<additional context>` |
| 4 | `<e.g., Data table>` | Table | Yes | `<additional context>` |
| 5 | `<e.g., Help text>` | Body text | No | `<additional context>` |

---

## Interactive Elements

For each interactive element on the screen, define its states and behavior.

### Element: `<Element Name>`

| Property | Value |
|---|---|
| **Type** | Button / Link / Input / Select / Toggle / Tab / etc. |
| **Label** | `<visible label text>` |
| **Action** | `<what happens on interaction>` |

#### States

| State | Visual Treatment | Notes |
|---|---|---|
| Default | `<appearance>` | |
| Hover | `<appearance change>` | |
| Focus | `<focus ring / outline style>` | Must be visible — WCAG 2.4.7 |
| Active | `<pressed appearance>` | |
| Disabled | `<grayed out, reduced opacity>` | Include `aria-disabled` and tooltip explaining why |
| Loading | `<spinner, skeleton, or progress>` | Announce to screen readers via `aria-live` |
| Error | `<error styling, message placement>` | Message must be associated via `aria-describedby` |

---

## Data States

Define what the screen looks like in each data condition.

| State | Description | What the User Sees |
|---|---|---|
| **Loading** | Data is being fetched | `<skeleton screen / spinner / progress bar>` |
| **Empty** | No data exists yet | `<empty state illustration + call to action>` |
| **Populated** | Normal data display | `<default layout as described above>` |
| **Error** | Data fetch failed | `<error message + retry action>` |
| **Partial** | Some data loaded, some failed | `<loaded sections visible, failed sections show inline error>` |

---

## Navigation & Transitions

| Action | Destination | Transition |
|---|---|---|
| `<e.g., Click "Create" button>` | `<target screen or modal>` | `<slide, fade, modal overlay, page navigation>` |
| `<e.g., Click breadcrumb>` | `<parent screen>` | `<page navigation>` |
| `<e.g., Press Escape>` | `<close modal>` | `<fade out, return focus to trigger>` |

---

## Accessibility Notes

| Requirement | Implementation |
|---|---|
| **Landmark regions** | `<e.g., header=banner, sidebar=navigation, main=main, footer=contentinfo>` |
| **Heading hierarchy** | `<e.g., h1: page title, h2: section headings, h3: subsections>` |
| **Focus management** | `<e.g., on modal open focus moves to modal, on close returns to trigger>` |
| **Skip link** | `<present / not needed — explain>` |
| **Live regions** | `<which dynamic content uses aria-live and at what politeness level>` |
| **Keyboard shortcuts** | `<any custom shortcuts and their discoverability>` |

---

## Open Questions

| # | Question | Status | Resolution |
|---|---|---|---|
| 1 | `<design question>` | Open / Resolved | `<resolution if resolved>` |
| 2 | `<design question>` | Open / Resolved | `<resolution if resolved>` |
