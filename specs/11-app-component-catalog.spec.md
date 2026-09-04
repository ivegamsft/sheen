# Spec 11 — App Component Catalog Agent Contract

> Normative behavior and output contract for an agent that audits, generates,
> and documents an application-specific catalog of logical UI components.
> Implements ADR-011 and composes with Spec 10.
>
> Status: **Draft v0.1**

## 1. Purpose

The App Component Catalog describes the reusable logical UI components that
belong to one application and gives an agent enough context to select, place,
compose, and document them correctly.

The capability MUST support:

- **Audit mode** — discover existing components and usages, normalize aliases,
  identify duplication and misuse, and document the current catalog.
- **Generate mode** — select or specify the logical component needed for an
  application context and add it to the app-specific gallery.

Both modes MUST use the same logical component contract.

## 2. Implementation neutrality

This specification governs agent reasoning and required metadata. It does not
dictate:

- programming language, UI framework, or component API;
- CSS methodology, class names, or styling library;
- repository paths, serialization format, or documentation platform;
- rendering, preview, story, design-tool, or gallery technology;
- package manager, dependency format, or distribution mechanism.

The agent MUST adapt to the downstream application's own design system and
implementation conventions.

## 3. Starting point and source precedence

The agent MUST use this precedence:

1. the downstream application's accepted design system and existing component
   contracts;
2. observed component usage, product behavior, and evidence;
3. application needs from its Experience Blueprint, pages, layouts, and flows;
4. user research, platform conventions, accessibility requirements, and domain
   constraints;
5. Sheen's neutral seed vocabulary and external reference research.

The seed vocabulary is a gap-detection and naming aid, not a default component
library. The agent MUST NOT copy another design system's components, visual
style, code, API, or implementation assumptions.

## 4. Reference model

The contract takes structural inspiration from:

- [Component Gallery](https://component.gallery/) — normalized component
  concepts, aliases, examples across multiple design systems, nesting, and
  guidance that a design system needs more than component screenshots;
- [shadcn/ui](https://ui.shadcn.com/) — discoverable registries, composable
  primitives and blocks, explicit dependencies, and ownership of downstream
  implementations.

Reusable ideas are taxonomy, aliases, composition, dependency relationships,
metadata, discoverability, and gallery views. React, Tailwind CSS, registry
JSON, source files, component APIs, and visual treatments are out of scope for
this agent contract.

## 5. Catalog layers

The agent MUST distinguish three layers:

1. **Neutral seed vocabulary** — common logical component roles used only to
   start discovery and detect likely gaps.
2. **App-specific logical catalog** — the authoritative component concepts,
   usage rules, relationships, and metadata for the downstream application.
3. **Implementation bindings** — optional downstream-owned references to the
   code, design assets, previews, tests, or packages that realize a logical
   component.

A logical component MAY have zero, one, or multiple implementation bindings.
The agent MUST NOT treat a binding as the component's complete design contract.

## 6. Neutral seed vocabulary

The agent SHOULD begin discovery with these role families:

| Family | Example logical roles |
|---|---|
| Actions | primary action, secondary action, link action, menu action |
| Input and selection | text input, choice, select, date/time, file, search |
| Navigation | global navigation, local navigation, breadcrumb, tabs, pagination, step progress |
| Feedback and status | alert, notification, validation message, progress, loading placeholder |
| Disclosure and overlays | accordion, dialog, drawer, popover, tooltip |
| Content and media | heading, body content, image/media, avatar, badge, metadata |
| Data display | list, table, key-value details, metric, chart container |
| Structure | section, card/group, divider, toolbar, action bar |
| Task composition | form, filter controls, search results, review summary, confirmation |

These are conceptual prompts, not a required inventory. The agent MUST remove,
rename, combine, or extend roles to fit the application's own language and
design system.

## 7. Logical component contract

Each catalog entry MUST include the following concepts.

### 7.1 Identity and provenance

- stable component ID;
- canonical app-specific name and aliases;
- concise purpose and user problem solved;
- family, role, maturity, owner, and review status;
- authoritative sources and evidence;
- relationship to an upstream/shared component, if any;
- optional implementation and design-asset bindings.

### 7.2 Usage rules

- use when;
- do not use when;
- preferred alternatives and decision boundaries;
- applicable audiences, tasks, page types, and experience archetypes;
- required, optional, restricted, or prohibited contexts;
- characteristic misuse and anti-patterns.

### 7.3 Placement rules

- allowed layout-region roles;
- prohibited layout-region roles;
- applicable IA levels and navigation contexts;
- prominence, frequency, density, and repetition constraints;
- required adjacency or separation from other roles;
- modal, inline, persistent, sticky, transient, or overlay behavior;
- page, flow, and journey relationships.

Placement rules MUST use logical roles rather than framework selectors or
fixed coordinates.

### 7.4 Composition

- parent and container roles;
- child, slot, or content roles;
- required and optional subcomponents;
- compatible and incompatible sibling components;
- logical dependencies;
- replacement, extension, and composition rules;
- maximum useful nesting or repetition where relevant.

The agent MUST distinguish a component from a multi-component pattern and from
a page layout. Components can compose into patterns; patterns and components
can occupy layout regions.

### 7.5 Styling abstractions

- semantic token roles;
- visual emphasis and hierarchy;
- density, size, and spacing behavior;
- shape, border, elevation, imagery, icon, and motion roles;
- theme and high-contrast expectations;
- allowed variants and prohibited visual divergence.

Styling metadata MUST describe intent and abstractions. It MUST NOT prescribe a
CSS framework, raw class list, or another design system's visual treatment.

### 7.6 Data and content requirements

- data purpose and domain entity;
- required and optional fields;
- cardinality, ordering, grouping, filtering, and pagination needs;
- data freshness and update behavior;
- loading, empty, partial, error, stale, and permission states;
- sensitive-data, privacy, localization, and formatting considerations;
- copy, label, help, and error-message requirements.

The contract MAY reference an existing data or API contract. It MUST NOT invent
backend fields as if they already exist.

### 7.7 Behavior and states

- default, hover, focus, active, selected, disabled, loading, error, and success
  behavior as applicable;
- trigger, dismissal, confirmation, and undo behavior;
- keyboard, pointer, touch, voice, and assistive-technology expectations;
- focus management, announcements, and semantic role;
- destructive, irreversible, or high-risk interaction treatment.

### 7.8 Responsive and adaptive behavior

- content priority and minimum useful presentation;
- allowed resizing, reflow, wrapping, stacking, collapsing, substitution, or
  overflow behavior;
- behavior in constrained, expanded, touch, and high-density contexts;
- information or actions that MUST remain available;
- circumstances where a different logical component is preferred.

Responsive behavior MUST describe adaptation, not only breakpoint values.

### 7.9 Selection metadata

The agent MUST be able to compare candidates using:

- user intent and task criticality;
- content/data type and cardinality;
- available region role and space;
- IA depth and navigation context;
- interaction complexity and frequency;
- audience expertise and accessibility needs;
- device/input context;
- density, urgency, and persistence;
- existing app patterns and consistency cost.

## 8. Gallery contract

The app-specific gallery is a documented view of the logical catalog. It MUST
support discovery by:

- canonical name and alias;
- family and role;
- user task and page type;
- layout-region role;
- data shape and interaction type;
- maturity and review status;
- usage restriction or risk;
- composition and dependency.

Each gallery entry MUST show the component's purpose, use/do-not-use guidance,
placement rules, states, responsive behavior, data needs, composition, and
provenance. A visual example MAY be included but MUST NOT substitute for the
logical specification.

## 9. Audit workflow

Audit mode MUST:

1. Load the downstream design system, component documentation, accepted
   decisions, Experience Blueprint, layout catalog, and pattern library.
2. Inventory implementation bindings, design assets, previews, tests, and
   observed page usage within the stated scope.
3. Group likely equivalents using purpose, semantics, behavior, and aliases,
   not appearance or name alone.
4. Create or update logical entries from evidence.
5. Compare actual placement and composition with documented rules.
6. Identify duplicate concepts, divergent bindings, undocumented one-offs,
   missing states, inaccessible behavior, and unsupported usage.
7. Record findings with evidence, confidence, impact, affected pages/layouts,
   and a recommended catalog action.

Audit mode MUST distinguish:

- one logical component with legitimate variants;
- one logical component with implementation drift;
- multiple components with genuinely different intent;
- a component, pattern, layout region, and page.

## 10. Generate workflow

Generate mode MUST:

1. Load the application's design system and app-specific catalog.
2. Read the relevant audience, task, flow, page, layout region, data, state,
   responsive, and accessibility context.
3. Search the catalog using names, aliases, roles, intent, and constraints.
4. Reuse an existing logical component when it satisfies the need.
5. Extend an existing component only when the new requirement preserves its
   core purpose and semantics.
6. Specify a new logical component only when no existing entry or composition
   satisfies the distinct user need.
7. Complete every required metadata area in section 7.
8. Test candidate placement against layout, IA, page, and flow constraints.
9. Add the accepted component to the app-specific gallery and document why it
   was reused, extended, or created.

The agent MUST NOT generate a new component merely because a requested visual
treatment differs.

## 11. Agent selection behavior

When determining proper usage and placement, the agent MUST:

1. eliminate components whose do-not-use, placement, data, responsive, or
   accessibility constraints conflict with the context;
2. prefer existing app components over new concepts;
3. prefer familiar platform and domain patterns when they satisfy the task;
4. compare the remaining candidates using section 7.9;
5. explain the selected component and rejected close alternatives;
6. identify uncertainty or missing evidence instead of fabricating certainty.

## 12. Relationship to other contracts

- **Experience Blueprint (Spec 10):** supplies audiences, tasks, archetypes,
  IA, pages, layouts, wireframes, navigation, and flows.
- **App Layout Catalog (Spec 12):** defines logical regions and the
  component roles those regions accept.
- **Shared component inventory:** identifies reusable upstream component
  concepts and maturity.
- **Pattern library:** owns multi-component interaction compositions.
- **Design tokens and aesthetic direction:** own semantic styling foundations.
- **Component specification:** owns detailed behavior for one component.
- **Frontend implementation:** realizes optional bindings without redefining
  the logical contract.

## 13. Validation requirements

Before completing an audit or generation task, the agent MUST check:

- every component has identity, purpose, usage, placement, composition,
  styling, data, state, responsive, and provenance metadata;
- aliases do not create ambiguous selection without a discriminator;
- component and pattern ownership are not conflated;
- placement rules reference known logical layout-region roles;
- required data and states are represented;
- responsive rules preserve critical information and actions;
- implementation bindings do not become the only documentation;
- new components include evidence that reuse or composition was insufficient.

The agent SHOULD flag:

- duplicate components with different names;
- one component name covering incompatible semantics;
- page-specific components that should be a pattern or composition;
- variants caused only by hard-coded visual differences;
- components with no known usage;
- components used outside their allowed contexts;
- undocumented dependencies or incompatible siblings;
- components whose mobile behavior removes the primary task.

## 14. Acceptance criteria

The feature is complete when a downstream agent can:

1. audit an existing application into an evidence-linked logical component
   catalog without assuming its implementation language or framework;
2. use the downstream design system as the starting point and the neutral seed
   vocabulary only as a gap check;
3. select the correct existing component for a page/layout context and explain
   the decision;
4. specify a new component only when a distinct unmet logical need exists;
5. document where each component should and should not appear;
6. document styling abstractions, data requirements, behavior, states,
   accessibility, responsive behavior, composition, and provenance;
7. present the catalog as a composable app-specific gallery in the
   downstream's chosen representation;
8. preserve links between component usage and Experience Blueprint pages,
   layouts, and flows.
