# Spec 12 — App Layout Catalog Agent Contract

> Normative behavior and output contract for an agent that audits, generates,
> and documents an application-specific catalog of logical page layouts.
> Implements ADR-012 and composes with Specs 10 and 11.
>
> Status: **Draft v0.1**

## 1. Purpose

The App Layout Catalog describes the reusable logical page structures that
belong to one application. It gives an agent enough context to select the
correct layout, place navigation, define component regions, preserve
information hierarchy, and adapt the structure across devices and states.

The capability MUST support:

- **Audit mode** — discover existing page structures, normalize equivalent
  layouts, identify structural drift and misuse, and document the current
  catalog.
- **Generate mode** — select, extend, or specify the logical layout needed for
  an application page and add it to the app-specific gallery.

Both modes MUST use the same logical layout contract.

## 2. Implementation neutrality

This specification governs agent reasoning and required layout metadata. It
does not dictate:

- programming language, UI framework, routing system, or rendering library;
- CSS grid, flexbox, native layout, canvas, or other layout technology;
- exact breakpoint values, columns, class names, or DOM structure;
- repository paths, serialization format, or documentation platform;
- design-tool frames, preview stories, screenshots, or gallery technology.

The agent MUST adapt to the downstream application's design system, platform,
layout foundations, and implementation conventions.

## 3. Starting point and source precedence

The agent MUST use this precedence:

1. the downstream application's accepted design system, layout foundations,
   navigation model, and product decisions;
2. observed page structures and evidence;
3. Experience Blueprint requirements for archetype, IA, pages, flows, and
   audiences;
4. the app-specific component catalog and pattern library;
5. user research, platform conventions, accessibility needs, and constraints;
6. Sheen's neutral layout-role seeds and external reference research.

Neutral seeds are gap-detection and reasoning aids. The agent MUST NOT copy
another product's layout, navigation, information architecture, visual style,
or implementation.

## 4. Catalog layers

The agent MUST distinguish:

1. **Neutral layout-role seeds** — common structural problems used to begin
   discovery.
2. **App-specific logical layout catalog** — authoritative reusable page-region
   structures and selection rules for the application.
3. **Page applications** — pages that select a logical layout and fill its
   regions with app components and patterns.
4. **Implementation bindings** — optional downstream-owned references to code,
   routes, design frames, previews, tests, or other realizations.

A layout defines regions and relationships. It does not define a complete
page's content, own component behavior, or prescribe a visual theme.

## 5. Neutral layout-role seeds

The agent SHOULD begin discovery with these layout families:

| Family | Optimized experience |
|---|---|
| Narrative landing | Explain a value proposition through ordered sections |
| Focused splash | Present one message, decision, or action with minimal distraction |
| Collection/discovery | Browse, search, filter, compare, and select items |
| Detail | Understand one entity and act on it |
| Dashboard overview | Monitor summarized status and drill into detail |
| Operational workbench | Prioritize, inspect, coordinate, and resolve live work |
| Master-detail | Move efficiently between a collection and selected item |
| Guided workflow | Complete a sequenced task with progress and validation |
| Form/settings | Review and edit structured configuration safely |
| Article/documentation | Read, navigate, understand, and apply long-form content |
| Search/results | Refine a query and evaluate ranked results |
| Authentication/gateway | Enter, recover, or select an account/context securely |

These are logical prompts, not required templates. The agent MUST remove,
rename, combine, specialize, or extend them to match the application.

## 6. Logical layout contract

Each catalog entry MUST include the following concepts.

### 6.1 Identity and provenance

- stable layout ID;
- canonical app-specific name and aliases;
- concise purpose and structural problem solved;
- family, maturity, owner, and review status;
- authoritative decisions, sources, and evidence;
- related upstream/shared layout concept, if any;
- optional implementation and design-asset bindings.

### 6.2 Usage rules

- use when;
- do not use when;
- preferred alternatives and decision boundaries;
- applicable experience archetypes, audiences, tasks, page types, and flows;
- required, optional, restricted, and prohibited contexts;
- characteristic misuse and anti-patterns.

### 6.3 IA and navigation applicability

- applicable IA levels, such as root, section, collection, detail, task, and
  utility;
- permitted depth and parent/child context;
- global, primary, local, contextual, utility, breadcrumb, tab, and in-page
  navigation roles;
- navigation placement, persistence, collapse, and priority;
- back, close, cancel, escape, and cross-context behavior;
- circumstances where navigation MUST be absent or visually reduced;
- route, deep-link, search, and wayfinding considerations.

The agent MUST distinguish navigation hierarchy from visual placement.

### 6.4 Region model

Each layout MUST define named logical regions. For each region, document:

- role and purpose;
- required, optional, conditional, repeatable, or prohibited status;
- reading and focus order;
- prominence and relationship to adjacent regions;
- allowed and prohibited logical component roles;
- minimum and maximum meaningful content;
- data and state dependencies;
- persistence, scrolling, sticky, overlay, or transient behavior;
- responsive transformation and fallback.

Common region roles MAY include:

- global header;
- primary navigation;
- local navigation;
- context header;
- breadcrumbs or location;
- summary or status;
- filters and controls;
- primary content;
- supporting content;
- detail or inspector;
- actions;
- feedback and system status;
- related content;
- footer or legal.

These roles are a vocabulary, not a required arrangement.

### 6.5 Component placement contract

A layout MUST constrain components by logical role rather than concrete
implementation. It MUST identify:

- roles allowed, preferred, restricted, or prohibited in each region;
- component cardinality and repetition limits;
- required component capabilities, such as dense comparison, bulk action,
  validation, or progressive disclosure;
- compatible patterns and incompatible compositions;
- cross-region dependencies and coordination;
- substitution rules when space or input mode changes.

The App Component Catalog owns component behavior and metadata. The layout owns
whether and where a component role fits.

### 6.6 Styling abstractions

- container and measure intent;
- hierarchy, emphasis, density, rhythm, and whitespace;
- semantic grid, alignment, spacing, divider, surface, elevation, and motion
  roles;
- full-width, constrained, split, layered, or edge-to-edge behavior;
- theme, high-contrast, and reading-comfort expectations;
- visual continuity and allowed structural variants.

Styling metadata MUST express design intent and token roles. It MUST NOT
prescribe framework classes or another system's exact dimensions.

### 6.7 Data and content requirements

- dominant content/data shape, such as narrative, collection, entity detail,
  comparison, hierarchy, timeline, map, or real-time status;
- expected cardinality and density;
- scan, compare, read, edit, monitor, or act behavior;
- freshness, update frequency, and live/streaming implications;
- loading, empty, partial, stale, error, permission, and offline behavior;
- localization, expansion, sensitive-data, and privacy constraints;
- minimum content needed for the layout to remain meaningful.

The layout MUST NOT invent backend fields or APIs.

### 6.8 Responsive and adaptive behavior

- priority order for regions and content;
- resize, reflow, stack, collapse, move, substitute, disclose, or remove rules;
- navigation transformation;
- region coordination across constrained and expanded contexts;
- touch, keyboard, pointer, voice, and assistive-technology implications;
- preservation of primary task, status, and recovery actions;
- threshold conditions that favor another logical layout.

Responsive behavior MUST describe semantic transformation, not only breakpoint
numbers.

### 6.9 Accessibility and interaction structure

- landmark roles and accessible names;
- intended reading, focus, and keyboard order;
- skip, bypass, and direct-navigation behavior;
- focus movement when regions open, close, appear, or relocate;
- zoom, reflow, text-spacing, and magnification considerations;
- treatment of persistent, sticky, overlay, and independently scrolling
  regions;
- announcements for significant structural or status changes.

### 6.10 Selection metadata

The agent MUST compare layout candidates using:

- page purpose and primary user task;
- experience archetype and IA level;
- navigation model and required wayfinding;
- content/data shape, cardinality, density, and update frequency;
- required component roles and patterns;
- number and priority of simultaneous tasks;
- audience expertise and accessibility needs;
- device, viewport, input, and operating context;
- persistence, urgency, and interruption level;
- consistency with existing app layouts and migration cost.

## 7. Gallery contract

The app-specific layout gallery is a documented view of the logical catalog.
It MUST support discovery by:

- canonical name and alias;
- layout family and page purpose;
- experience archetype and IA level;
- navigation model;
- region roles;
- data/content shape and density;
- compatible component roles and patterns;
- responsive transformation;
- maturity, review status, and risk.

Each entry MUST show its purpose, use/do-not-use guidance, region map,
navigation placement, IA applicability, component-role constraints, styling
abstractions, data needs, responsive behavior, accessibility structure, and
provenance.

A wireframe, screenshot, or rendered example MAY be included but MUST NOT
substitute for the logical layout specification.

## 8. Audit workflow

Audit mode MUST:

1. Load the downstream design system, layout foundations, navigation and IA
   decisions, Experience Blueprint, component catalog, and pattern library.
2. Inventory routes, pages, shells, templates, design frames, previews, tests,
   and observed responsive states within scope.
3. Group likely equivalent layouts by structural purpose, region
   relationships, navigation, and responsive behavior, not appearance alone.
4. Create or update logical layout entries from evidence.
5. Map pages to layouts and components/patterns to logical regions.
6. Compare actual usage with IA, navigation, region, data, accessibility, and
   responsive rules.
7. Record findings with evidence, confidence, user impact, affected pages and
   components, and recommended catalog action.

Audit mode MUST distinguish:

- one layout with legitimate variants;
- one layout with structural implementation drift;
- multiple layouts with genuinely different purpose;
- a layout, page, component, pattern, and application shell.

## 9. Generate workflow

Generate mode MUST:

1. Load the application's design system, Experience Blueprint, app layout
   catalog, app component catalog, and pattern library.
2. Read the page purpose, audience, task, archetype, IA level, navigation,
   data, component, state, responsive, and accessibility context.
3. Search the layout catalog using purpose, aliases, IA/navigation
   applicability, region roles, data shape, and constraints.
4. Reuse an existing logical layout when it satisfies the need.
5. Extend a layout only when the structural purpose and region semantics remain
   intact.
6. Specify a new logical layout only when no existing layout can support the
   distinct structural need without violating its contract.
7. Complete every metadata area in section 6.
8. Map required component roles to valid regions and identify unresolved
   component gaps.
9. Test responsive transformations, navigation, reading order, and critical
   states.
10. Add the accepted layout to the app-specific gallery and document why it
    was reused, extended, or created.

The agent MUST NOT create a new layout merely because a page uses different
content, colors, or component instances.

## 10. Agent selection behavior

When choosing a layout, the agent MUST:

1. eliminate layouts whose IA, navigation, region, data, responsive, or
   accessibility constraints conflict with the page;
2. prefer existing app layouts over new structures;
3. prefer familiar platform and domain structures when they support the task;
4. compare remaining candidates using section 6.10;
5. explain the selected layout and rejected close alternatives;
6. identify uncertainty, missing evidence, or unresolved component needs.

## 11. Relationship to other contracts

- **Experience Blueprint (Spec 10):** defines audiences, archetypes, IA, pages,
  navigation, wireframes, and flows that require layouts.
- **App Component Catalog (Spec 11):** defines the logical components and
  patterns eligible for layout regions.
- **Layout/grid/spacing foundations:** define shared scales and structural
  primitives.
- **Responsive design:** owns adaptation quality and behavior.
- **Information architecture and navigation:** own hierarchy, labels,
  findability, and wayfinding.
- **Content hierarchy:** owns priority and scan path.
- **Page specification:** selects a layout and fills its regions.
- **Frontend implementation:** realizes optional bindings without redefining
  the logical layout contract.

## 12. Validation requirements

Before completing an audit or generation task, the agent MUST check:

- every layout has identity, purpose, usage, IA/navigation, region, component,
  styling, data, responsive, accessibility, selection, and provenance
  metadata;
- every region has a role, status, order, component-role constraints, and
  responsive behavior;
- navigation placement matches the intended hierarchy and context;
- pages reference a layout suitable for their IA level and purpose;
- required component roles can be placed without violating catalog rules;
- critical information, actions, status, and recovery survive adaptation;
- implementation bindings do not become the only documentation;
- new layouts include evidence that reuse or extension was insufficient.

The agent SHOULD flag:

- structurally duplicate layouts with different names;
- one layout name covering incompatible purposes;
- page-specific arrangements that should reuse an existing layout;
- layouts differentiated only by visual styling;
- navigation placement inconsistent with IA level;
- regions with no allowed role or no known usage;
- independently scrolling or sticky regions with accessibility risk;
- responsive transformations that remove the primary task;
- pages whose component needs do not fit any valid region.

## 13. Acceptance criteria

The feature is complete when a downstream agent can:

1. audit an existing application into an evidence-linked logical layout
   catalog without assuming implementation technology;
2. use the downstream design system, IA, navigation, and observed structures as
   the starting point;
3. select the correct existing layout for a page and explain the decision;
4. specify a new layout only for a distinct unmet structural need;
5. document where each layout should and should not appear;
6. document navigation placement, IA applicability, regions, component-role
   constraints, styling abstractions, data needs, responsive behavior,
   accessibility structure, and provenance;
7. present layouts as a composable app-specific gallery in the downstream's
   chosen representation;
8. preserve traceability between layouts, Experience Blueprint pages/flows,
   and App Component Catalog entries.
