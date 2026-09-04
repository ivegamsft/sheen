---
# [Layout Name] — Logical Layout Catalog Entry

> Status: Draft | Version: 0.1.0 | Owner: [Team] | Last reviewed: [YYYY-MM-DD]
> Maturity: draft | beta | stable — Review status: [pending/accepted/deprecated]

---

## 1. Identity and provenance

- **Layout ID:** [stable-kebab-id]
- **Canonical name / aliases:** [Name] / [alias-1, alias-2]
- **Purpose:** [One sentence — the structural page problem this solves.]
- **Family:** [neutral seed family this specializes, extends, or replaces, if any]
- **Owner / review status:** [team] / [draft|accepted|deprecated]
- **Sources and evidence:** [design system decisions, observed pages, research links]
- **Related upstream/shared layout concept:** [none | sheen neutral seed name]
- **Implementation bindings (optional):** [routes, code, design frames, previews, tests]

---

## 2. Usage rules

- **Use when:** [page purpose / primary task]
- **Do not use when:** [conflicting purpose or structure]
- **Preferred alternatives:** [other catalog layout(s) and the boundary between them]
- **Applicable archetypes / audiences / tasks / page types / flows:** [list]
- **Required / optional / restricted / prohibited contexts:** [list]
- **Characteristic misuse / anti-patterns:** [list]

---

## 3. IA and navigation applicability

- **IA levels:** [root | section | collection | detail | task | utility]
- **Depth / parent-child context:** [description]
- **Navigation roles present:** [global, primary, local, contextual, utility, breadcrumb, tab, in-page]
- **Placement, persistence, collapse, priority:** [description]
- **Back / close / cancel / escape behavior:** [description]
- **When navigation MUST be absent or reduced:** [conditions]
- **Route / deep-link / wayfinding considerations:** [notes]

---

## 4. Region model

| Region | Role | Status | Order | Allowed component roles | Min/max content | Responsive behavior |
|---|---|---|---|---|---|---|
| [Global header] | | required/optional/conditional/repeatable/prohibited | | | | |
| [Primary navigation] | | | | | | |
| [Primary content] | | | | | | |
| [Supporting content] | | | | | | |
| [Actions] | | | | | | |
| [Feedback / system status] | | | | | | |

For each region also record: prominence and relationship to adjacent
regions; data/state dependencies; persistence/scroll/sticky/overlay/transient
behavior.

---

## 5. Component placement contract

- **Allowed / preferred / restricted / prohibited roles per region:** [list]
- **Cardinality and repetition limits:** [list]
- **Required component capabilities:** [dense comparison, bulk action, validation, progressive disclosure, ...]
- **Compatible patterns / incompatible compositions:** [list]
- **Cross-region dependencies:** [list]
- **Substitution rules when space/input mode changes:** [list]

---

## 6. Styling abstractions

- **Container / measure intent:** [full-width | constrained | split | layered | edge-to-edge]
- **Hierarchy, emphasis, density, rhythm, whitespace:** [description]
- **Semantic grid/alignment/spacing/divider/surface/elevation/motion roles:** [token roles, not values]
- **Theme / high-contrast / reading-comfort expectations:** [notes]
- **Allowed structural variants:** [list]

---

## 7. Data and content requirements

- **Dominant content/data shape:** [narrative | collection | entity detail | comparison | hierarchy | timeline | map | real-time status]
- **Cardinality and density:** [notes]
- **Scan / compare / read / edit / monitor / act behavior:** [notes]
- **Freshness / update frequency / live implications:** [notes]
- **Loading / empty / partial / stale / error / permission / offline behavior:** [notes]
- **Localization / expansion / sensitive-data / privacy constraints:** [notes]
- **Minimum content for the layout to remain meaningful:** [notes]

---

## 8. Responsive and adaptive behavior

- **Priority order for regions/content:** [ordered list]
- **Resize/reflow/stack/collapse/move/substitute/disclose/remove rules:** [notes]
- **Navigation transformation:** [notes]
- **Touch / keyboard / pointer / voice / assistive-technology implications:** [notes]
- **Preserved primary task, status, and recovery actions:** [notes]
- **Threshold conditions favoring another logical layout:** [notes]

---

## 9. Accessibility and interaction structure

- **Landmark roles and accessible names:** [list]
- **Reading / focus / keyboard order:** [notes]
- **Skip / bypass / direct-navigation behavior:** [notes]
- **Focus movement on region open/close/appear/relocate:** [notes]
- **Zoom / reflow / text-spacing / magnification considerations:** [notes]
- **Persistent/sticky/overlay/independently-scrolling region treatment:** [notes]
- **Announcements for structural or status changes:** [notes]

---

## 10. Selection metadata

Compared against candidates using: page purpose/primary task; experience
archetype and IA level; navigation model and wayfinding; content/data shape,
cardinality, density, update frequency; required component roles/patterns;
number/priority of simultaneous tasks; audience expertise and accessibility
needs; device/viewport/input/operating context; persistence/urgency/
interruption level; consistency with existing app layouts and migration cost.

- **Selected because:** [rationale]
- **Rejected alternatives:** [layout — reason]
- **Open uncertainty / missing evidence / unresolved component gaps:** [list]
