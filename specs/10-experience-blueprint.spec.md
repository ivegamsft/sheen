# Spec 10 — Experience Blueprint Agent Contract

> Normative behavior and output contract for an agent that audits, generates,
> and documents a downstream application's complete UI/UX experience.
> Implements ADR-010.
>
> Status: **Draft v0.1**

## 1. Purpose

An Experience Blueprint is the canonical, implementation-ready description of
how a product looks, reads, is structured, and moves users through tasks. It
MUST support two modes:

- **Audit mode** — observe an existing experience, compare it with its intended
  contract, record evidence and confidence, and prioritize remediation.
- **Generate mode** — create a new experience contract from product intent,
  audiences, tasks, constraints, and a selected experience archetype.

Both modes MUST produce the same logical artifact model so an audited
application can be incrementally improved without translating the audit into a
different conceptual contract.

## 2. Scope

The blueprint governs:

- branding and aesthetic direction;
- voice, tone, and representative UI copy;
- information architecture and content hierarchy;
- responsive layout structures;
- page and screen inventory;
- low-fidelity wireframe specifications;
- global, local, contextual, and utility navigation;
- user journeys, task flows, alternate paths, and recovery paths;
- cross-artifact traceability and validation.

The agent contract does not replace:

- DTCG tokens or generated `DESIGN.md`;
- `AESTHETIC-DIRECTION.md`;
- component specifications or runtime UI code;
- formal accessibility, security, or performance certification;
- analytics dashboards or reporting-diagram design.

Specialist artifacts remain authoritative in their domain. The agent MUST
index and relate them instead of copying their complete content.

## 3. Architecture

The agent MUST reason in three logical layers:

1. **Experience index** — canonical inventory and relationship model.
2. **Experience artifacts** — brand, IA, voice, layouts, pages, wireframes,
   navigation, and flows.
3. **Experience orchestration** — deterministic delegation to the relevant
   specialist capabilities.

The agent MUST NOT reimplement brand, IA, accessibility, component, or
frontend expertise already owned by another capability.

## 4. Implementation neutrality

This specification defines agent behavior and logical output. It does not
dictate:

- programming language, UI framework, or rendering library;
- repository paths or folder names;
- Markdown, YAML, JSON, database, design-tool, or document formats;
- diagram, wireframe, or gallery technology;
- build, storage, hosting, or generation implementation.

The downstream consumer MAY choose any representation that preserves the
required concepts, relationships, evidence, and validation outcomes. The agent
SHOULD adapt to existing project conventions and tools.

### 4.1 Starting point and source precedence

The agent MUST use this precedence when auditing or generating an experience:

1. the downstream application's accepted design system and product decisions;
2. observed application behavior and evidence;
3. user research, domain needs, platform conventions, and stated constraints;
4. Sheen's neutral archetypes, catalogs, and external reference research.

Reference galleries and design systems MAY inspire taxonomy, metadata,
composition, documentation structure, and questions the agent should ask. The
agent MUST NOT copy their components, layouts, styling, code, naming, or
implementation assumptions into a downstream whose own design system differs.

## 5. Experience index contract

The output MUST include an index that identifies:

- experience name, mode, status, and scope;
- primary and supporting archetypes;
- audiences, goals, platforms, and contexts;
- the available brand, voice, IA, layout, page, wireframe, navigation, and flow
  artifacts;
- stable identifiers and relationships between artifacts;
- authoritative sources, decisions, assumptions, and unresolved questions;
- generated or rendered views derived from the logical contract.

Referenced identifiers MUST be unique and stable within the application.
The representation MAY use links, keys, document anchors, tool-native IDs, or
another unambiguous mechanism.

## 6. Domain artifact contracts

### 6.1 Brief

The brief MUST define:

- product outcome and non-goals;
- primary audiences, jobs, and contexts;
- platforms, breakpoints, and input modes;
- content and data constraints;
- accessibility, localization, privacy, and security constraints;
- success measures and unresolved assumptions.

### 6.2 Brand

The brand artifact MUST reference or define:

- brand principles and visual identity constraints;
- approved aesthetic direction and token/theme references;
- typography, color, imagery, iconography, and motion character;
- approved patterns, prohibited treatments, and exceptions.

It MUST link to `DESIGN.md`, `AESTHETIC-DIRECTION.md`, or equivalent sources
when those artifacts exist instead of duplicating exact token values.

### 6.3 Voice

The voice artifact MUST define:

- stable voice principles;
- tone-by-context matrix;
- terminology and lexicon references;
- representative navigation, action, empty, error, success, and help copy;
- prohibited language and localization notes.

### 6.4 Information architecture

The IA artifact MUST define:

- content and domain objects;
- sitemap or screen hierarchy;
- labels and taxonomy references;
- global, local, contextual, and utility navigation groups;
- findability rules, search role, and maximum intended depth;
- orphan, duplicate, and migration handling.

### 6.5 Layouts

Each layout specification MUST follow the App Layout Catalog contract in
Spec 12 (implemented as the `app-layout-catalog` skill) and define:

- layout ID, purpose, and compatible archetypes;
- named regions and reading order;
- columns, containers, gutters, density, and spacing-token references;
- responsive reflow rules by breakpoint;
- persistent, conditional, and optional regions;
- accessibility landmarks and focus-order implications.

Layouts are structural contracts, not pixel-perfect mockups.

### 6.6 Pages

Each page specification MUST define:

- page ID, title, route pattern, purpose, and owning flow;
- audience and permission applicability;
- selected layout and navigation placement;
- content hierarchy and major component/pattern references;
- loading, empty, partial, error, success, and permission states;
- responsive exceptions, SEO/discoverability needs where applicable;
- inbound and outbound transitions.

### 6.7 Wireframes

Each wireframe specification MUST:

- reference exactly one page ID;
- show layout regions and content priority;
- annotate interaction targets and state changes;
- include desktop and mobile behavior when the platform is responsive;
- remain low fidelity unless the brief explicitly requests visual comps;
- avoid embedding inaccessible text-only meaning in an image.

The agent MAY use any downstream-supported representation. It MUST preserve
the annotations and relationships needed for review and revision.

### 6.8 Flows

Each flow specification MUST define:

- flow ID, audience, trigger, goal, entry points, and success outcome;
- ordered steps linked to page IDs;
- decisions, branches, alternate paths, cancellation, and recovery;
- cross-channel transitions and external dependencies;
- measurable completion, error, and drop-off criteria;
- unresolved gaps and owner.

Flow diagrams MAY illustrate the contract, but they MUST NOT be the only place
where steps, decisions, alternate paths, and recovery are described.

## 7. Experience archetypes

An archetype is a composable starting constraint, not a finished theme or a
fixed sitemap. Sheen SHOULD initially provide:

| Archetype | Primary optimization | Required moments |
|---|---|---|
| `marketing-home` | Explain value and establish trust | hero, proof, benefits, conversion, footer |
| `campaign-splash` | Focus attention on one message or action | message, proof, primary action, legal |
| `commerce` | Find, compare, select, and purchase | discovery, detail, cart, checkout, confirmation |
| `dashboard` | Monitor status and act on summarized information | overview, drill-down, filters, alerts, empty/error |
| `control-tower` | Detect, prioritize, coordinate, and resolve operations | situation view, queue, detail, action, escalation |
| `workflow-app` | Complete a multi-step business task | start, progress, validation, review, completion |
| `docs-knowledge` | Find, understand, and apply information | browse, search, article, related content, feedback |
| `admin-settings` | Configure policy and preferences safely | overview, categories, edit, validation, audit history |

Consumers MAY compose one primary and multiple supporting archetypes. For
example, a commerce administration product can use `commerce` as primary and
`dashboard` plus `admin-settings` as supporting archetypes.

Custom archetypes MUST declare:

- the user outcome they optimize;
- required and optional experience moments;
- default navigation and layout tendencies;
- characteristic risks and anti-patterns;
- compatibility with other archetypes.

They MUST NOT prescribe brand styling or runtime components.

## 8. Audit workflow

Audit mode MUST:

1. Inventory available routes, screens, navigation, content, styles, copy,
   components, analytics, tests, and existing design documentation.
2. Record each source in an evidence register with location, capture date,
   evidence type, and confidence.
3. Infer the current archetype composition and mark assumptions explicitly.
4. Populate the core experience contract with observed behavior.
5. Evaluate coherence across brand, voice, IA, layout, pages, navigation, and
   flows.
6. Record findings with severity, evidence, affected artifact IDs, user impact,
   recommendation, and owner.
7. Separate observed facts from inferred intent and proposed future state.

An audit MUST NOT claim a page, flow, or state is absent unless the audited
scope and evidence sources make that conclusion supportable.

## 9. Generate workflow

Generate mode MUST:

1. Establish the brief, audiences, primary jobs, constraints, and success
   measures.
2. Select a primary archetype and any supporting archetypes.
3. Generate at least two candidate IA/layout directions when material design
   uncertainty exists.
4. Resolve the direction through `design-debate`.
5. Produce the logical artifacts in dependency order:
   brief → brand/voice → IA → layouts → pages → wireframes → flows.
6. Validate cross-references, state coverage, responsive behavior, and
   specialist constraints.
7. Produce a downstream handoff and identify implementation dependencies.

Generation MUST use existing project decisions and assets when present. It
MUST NOT silently replace an accepted brand, token, IA, or component contract.

## 10. Audit scoring

Audit findings SHOULD include a 0–4 maturity score for each dimension:

| Score | Meaning |
|---|---|
| 0 | Missing or unusable |
| 1 | Ad hoc and inconsistent |
| 2 | Partially defined |
| 3 | Defined and mostly consistent |
| 4 | Governed, validated, and traceable |

Required dimensions are brand, voice, IA, layout, page/state coverage,
navigation, task-flow continuity, responsive/accessibility readiness, and
cross-artifact coherence.

Every score MUST include evidence and confidence. Scores are prioritization
signals, not compliance certifications.

## 11. Skill and agent integration

The orchestrator MUST delegate domain work:

| Concern | Primary capability |
|---|---|
| Brand and visual identity | `brand-identity`, `design-tokens`, `theming` |
| Voice and terminology | `brand-voice-tone`, `ux-writing`, `lexicon` |
| IA and navigation | `information-architecture`, `navigation-design`, `taxonomy` |
| Layout and page structure | `layout-grid-spacing`, `responsive-design`, `content-hierarchy`, `app-layout-catalog` |
| Wireframes and journeys | `wireframing`, `ux` templates, `user-research` |
| Components and patterns | `app-component-catalog`, `component-spec`, `pattern-library`, `ui-states-interaction` |
| Audit and quality | `design-audit`, `design-system-audit`, `web-usability-review` |
| Accessibility and secure UX | `accessibility-audit`, `secure-ux` |
| Direction selection | `design-exploration`, `design-debate` |
| Implementation handoff | `design-handoff`, `design-to-code`, `frontend-dev` |

Routing SHOULD expose one experience-level capability that coordinates the
existing specialists rather than creating a new specialist for every artifact.

## 12. Validation requirements

Before completing the task, the agent MUST check:

- required concepts and relationships are present;
- identifier uniqueness and stability;
- all referenced artifacts and IDs resolve;
- every page references a valid layout;
- every flow step references a valid page or declared external touchpoint;
- every responsive page has breakpoint behavior;
- required page states are present or explicitly `not-applicable`;
- audit findings reference valid evidence and artifact IDs;
- generated or rendered summaries identify their authoritative sources.

The agent SHOULD also check:

- orphan pages and unreachable navigation destinations;
- flows without recovery or cancellation;
- layouts with conflicting region or reading-order rules;
- voice examples missing common system states;
- archetype-required moments not represented by a page or flow;
- duplicate routes, labels, or page purposes.

## 13. Acceptance criteria

The feature is complete when:

1. A downstream agent can audit an existing application and produce the
   complete logical contract, evidence register, scored findings, and
   prioritized remediation plan.
2. A downstream agent can generate a new experience from a product brief and
   produce brand, voice, IA, layouts, pages, wireframes, navigation, and flows.
3. Both modes use the same concepts and relationship rules.
4. The agent can apply at least the eight archetypes in section 7 as reusable
   reasoning templates.
5. Archetypes can be composed without redefining their shared intent.
6. Existing tokens, aesthetic direction, lexicon, component inventory, and
   pattern library are referenced rather than duplicated.
7. The generated documentation is source-linked, reviewable, and suitable for
   both human review and agent implementation.
8. Routing evals distinguish experience-level audit/generation from component,
   brand-only, IA-only, and frontend implementation requests.

## 14. Contract evolution

- Required concepts and relationship semantics MUST remain stable within a
  published major version of this agent contract.
- Adding optional metadata or archetypes is backward compatible.
- Removing or redefining required concepts requires migration guidance.
- Archetype IDs are stable once published; replacement requires a deprecation
  period.
