# App Layout Catalogs

An App Layout Catalog is the application-specific gallery of logical page
structures an agent can use when generating or auditing pages. A layout defines
regions, hierarchy, navigation placement, component-role constraints, and
responsive transformation. It does not define a complete page or prescribe a
rendering technology.

## Start with the app

Use this source order:

1. the application's accepted design system and layout foundations;
2. its IA, navigation model, and observed page structures;
3. the Experience Blueprint, pages, tasks, audiences, and flows;
4. the App Component Catalog and pattern library;
5. research, platform conventions, accessibility needs, and constraints;
6. neutral layout-role seeds and external references.

Do not copy another site's page templates, information architecture,
navigation, breakpoints, grid, style, or implementation.

## Four layers

| Layer | Purpose |
|---|---|
| Neutral seed | Prompts discovery and exposes likely structural gaps |
| App logical catalog | Defines reusable regions, rules, and selection metadata |
| Page application | Selects a layout and fills regions with app components/patterns |
| Optional binding | Points to code, routes, frames, previews, or tests |

This separation lets an app change its framework or rendering while preserving
the reason a layout exists and the pages that should use it.

## What every layout entry answers

- What page problem and primary task does it support?
- When should it be used, and when should it not?
- Which experience archetypes, page types, and IA levels fit?
- Where do global, primary, local, contextual, and utility navigation belong?
- Which regions exist, and which are required, optional, conditional, or
  prohibited?
- Which logical component roles can occupy each region?
- Which data shapes, cardinality, density, and freshness fit?
- How do hierarchy, spacing, surfaces, and emphasis use design abstractions?
- How do regions and navigation transform in constrained contexts?
- What are the reading order, landmarks, focus behavior, and bypass paths?
- Which pages and implementation bindings realize the layout?

## Audit an existing app

1. Load the app's design system, IA, navigation decisions, Experience
   Blueprint, component catalog, and pattern library.
2. Inventory pages, shells, templates, frames, previews, tests, and responsive
   states.
3. Group structures by purpose, regions, navigation, and adaptation rather
   than visual similarity alone.
4. Separate legitimate variants from structural drift and duplicate layouts.
5. Map pages to layouts and components to region roles.
6. Identify one-offs, inconsistent navigation, inaccessible reading/focus
   order, invalid placement, and responsive loss of critical tasks.
7. Prioritize remediation by user impact and affected pages/flows.

## Generate or select a layout

1. Read the page purpose, primary task, archetype, IA level, navigation model,
   data shape, component needs, states, and device context.
2. Search the app catalog by purpose, alias, IA/navigation applicability,
   region roles, and data constraints.
3. Eliminate layouts that conflict with required navigation, regions,
   components, responsive behavior, or accessibility structure.
4. Reuse an existing layout when it fits.
5. Extend it only when the structural purpose and region semantics remain.
6. Specify a new layout only for a distinct unmet structural need.
7. Document why close alternatives were rejected.
8. Add it to the app gallery in the downstream's chosen representation.

Different content, colors, or component instances do not by themselves justify
a new logical layout.

## Neutral seed families

Use narrative landing, focused splash, collection/discovery, detail, dashboard
overview, operational workbench, master-detail, guided workflow, form/settings,
article/documentation, search/results, and authentication/gateway as an initial
gap checklist.

These are not finished templates. The app can rename, combine, specialize, or
remove them.

## Gallery views

The gallery should let agents and people browse by:

- name and family;
- page purpose and primary task;
- experience archetype and IA level;
- navigation model;
- region roles;
- data shape and density;
- compatible component roles and patterns;
- responsive transformation;
- maturity, risk, and review status.

Wireframes and previews are useful but optional. Region, selection,
navigation, responsive, and accessibility guidance remains required.

## Boundary rules

- An **experience archetype** defines required moments and optimization goals.
- A **layout** defines reusable page regions and structural relationships.
- A **page** selects a layout and supplies specific content, components, and
  transitions.
- A **component** is a reusable logical interface unit placed in a region.
- A **pattern** is a proven multi-component interaction composition.
- An **implementation binding** realizes the layout in downstream technology.

The normative behavior, metadata, workflows, and acceptance criteria are in
`specs/12-app-layout-catalog.spec.md`. The `app-layout-catalog` skill
(composed by the `ux-designer` agent) implements this workflow; starter
templates for a logical layout entry, an audit finding, and worked
reuse/extend/create scenarios are in `skills/app-layout-catalog/templates/`.
