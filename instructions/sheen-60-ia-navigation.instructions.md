---
name: sheen-60-ia-navigation
compatibility: [github-copilot-cli]
description: "Always-on information architecture and navigation pattern rules."
applyTo: "**/*"
metadata:
  band: 60
  layer: information-architecture
---

# Information Architecture and Navigation

Apply these rules when designing, reviewing, or auditing the structure and
navigability of any product surface. Good IA makes content findable; good
navigation makes it reachable.

## IA fundamentals

- **Organize by user mental model, not system structure.** Users look for
  information the way they think about it, not the way the database stores it.
  Conduct card sorting or tree testing to validate groupings before committing.
- **One primary path per task.** A user trying to do a task should encounter one
  clear path, not multiple competing routes.
- **Consistent labeling.** The same concept must carry the same label across the
  product. Synonyms in navigation are a usability defect.
- **Shallow over deep.** Prefer breadth over depth in navigation hierarchies.
  Three levels is the practical maximum before wayfinding breaks. Flatten where
  possible.
- **Findability audit:** every significant piece of content or action must be
  reachable from the home/root in three clicks or taps.

## Navigation patterns

Select navigation patterns based on content volume and user journey type:

| Pattern | When to use |
|---|---|
| Top navigation bar | Primary site/app sections (2-7 items). Always visible. |
| Side navigation / rail | Large catalogs or admin surfaces with many sections. Collapsible on mobile. |
| Tabs | Secondary content within a page or panel (2-7 tabs). Do not nest tabs. |
| Breadcrumbs | Deep hierarchies (3+ levels). Always include home as the first item. |
| Contextual / inline links | Related content within a flow. Not a substitute for primary nav. |
| Bottom navigation (mobile) | 3-5 primary destinations on mobile. Thumb-reachable zone. |

## Wayfinding requirements

- The user must always know **where they are** (active state in nav, page title,
  breadcrumb).
- The user must always know **where they can go** (visible nav items, clear CTAs).
- The user must always know **how to get back** (browser back is not enough; provide
  breadcrumbs or a back affordance in multi-step flows).
- Active navigation items must be visually distinguished from inactive ones using
  more than color alone (weight, underline, icon, or indicator).

## Search and filter

- Search must be present when the catalog exceeds what fits on one screen without
  scrolling.
- Filters must be in a consistent location (top or left rail) and show the active
  filter state clearly.
- An empty search result must offer suggestions or alternative paths, not just
  "No results found."

## Mobile and responsive IA

- Navigation must remain accessible on small screens. A hamburger menu is
  acceptable for secondary nav; primary destinations should be in the bottom nav
  bar or a persistent header on mobile.
- Touch targets must meet the 44 x 44 CSS px minimum (from accessibility baseline).
- Do not hide critical navigation behind gestures not afforded by the platform
  (swipe-only navigation is a usability defect unless paired with visible controls).

## Review lens

Before finalizing any IA or navigation recommendation, ask:

- Is the navigation organized by user mental model or system structure?
- Is labeling consistent across all surfaces?
- Can every significant action or content be reached in three clicks or fewer?
- Does the user always know where they are, where they can go, and how to get back?
- Is the active state distinguished by more than color alone?
- Is search available when the catalog warrants it?
- Is the navigation pattern appropriate for the content volume and user journey?
