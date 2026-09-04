# App Component Catalogs

An App Component Catalog is the application-specific gallery of logical UI
components an agent can use when composing layouts and pages. It documents not
only what components exist, but how to choose, place, combine, and adapt them.

## Start with the app, not a library

Use this source order:

1. the application's accepted design system;
2. observed product behavior and existing component usage;
3. the Experience Blueprint, page needs, layouts, and flows;
4. user research, platform conventions, and constraints;
5. a neutral seed vocabulary and external references.

[Component Gallery](https://component.gallery/) is useful inspiration for
component names, aliases, cross-system comparison, nesting, and use/do-not-use
guidance. [shadcn/ui](https://ui.shadcn.com/) is useful inspiration for
composable primitives and blocks, dependencies, ownership, registries, and
browsable galleries.

Do not copy either source's components, visuals, code, APIs, framework choices,
or catalog implementation. Every downstream has its own design system.

## Three layers

| Layer | Purpose |
|---|---|
| Neutral seed | Prompts discovery and exposes likely gaps |
| App logical catalog | Defines component intent, rules, metadata, and relationships |
| Optional bindings | Points to the app's code, design assets, previews, and tests |

The logical catalog survives technology changes. A component binding can be
replaced without changing why the component exists or where it belongs.

## What every component entry answers

- What user problem does it solve?
- What does this application call it, and what are its aliases?
- When should it be used, and when should it not?
- Which page types, IA levels, navigation contexts, and layout regions allow
  it?
- Which placements or combinations are prohibited?
- What contains it, and what can it contain?
- Which semantic styling roles and variants apply?
- What data, content, permissions, and system states does it require?
- How does it behave with keyboard, pointer, touch, and assistive technology?
- How does it reflow, collapse, substitute, or preserve priority responsively?
- Where did the decision come from, and which implementation realizes it?

## Audit an existing app

1. Load the app's design system, Experience Blueprint, layout catalog, shared
   inventory, and pattern library.
2. Inventory existing implementations, design assets, previews, tests, and
   page usage.
3. Group candidates by intent and semantics, using aliases only as supporting
   evidence.
4. Separate legitimate variants from implementation drift and duplicate
   concepts.
5. Document logical entries and compare actual usage with placement rules.
6. Identify one-offs, missing states, inaccessible behavior, unused entries,
   ambiguous names, and misuse.
7. Prioritize remediation by user impact and affected pages/flows.

## Generate or select a component

1. Read the user task, page purpose, layout region, data shape, states,
   responsive context, and constraints.
2. Search the app catalog by intent, role, alias, placement, and data needs.
3. Eliminate candidates with conflicting do-not-use or placement rules.
4. Reuse an existing component when it fits.
5. Extend it only when the core purpose and semantics remain intact.
6. Specify a new component only for a distinct unmet need.
7. Document the complete logical contract and why close alternatives were
   rejected.
8. Add it to the app gallery in the downstream's chosen format.

A different color, border, or spacing treatment is not sufficient reason for a
new logical component.

## Seed role families

Use actions, inputs, navigation, feedback, disclosure, content/media, data
display, structure, and task composition as an initial gap checklist. The app
can rename, combine, remove, or extend these families.

The seed is successful when it helps the agent ask better questions. It fails
when it becomes a mandatory generic component list.

## Gallery views

The gallery should let agents and people browse by:

- name and alias;
- family and logical role;
- user task and page type;
- layout-region role and IA level;
- data shape and interaction type;
- maturity, risk, and review status;
- composition and dependency.

Visual previews are useful but optional. Usage and placement guidance remains
required even when no preview exists.

## Boundary rules

- A **component** is a reusable logical interface unit.
- A **pattern** is a proven composition of multiple components for an
  interaction scenario.
- A **layout** defines page regions and structural relationships.
- A **page** applies a layout and fills regions with components and patterns.
- An **implementation binding** realizes a logical component in the
  downstream's selected technology.

The normative behavior, metadata, workflows, and acceptance criteria are in
`specs/11-app-component-catalog.spec.md`.
