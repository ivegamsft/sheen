# App Component Catalog Template

Use `docs/guides/app-component-catalogs.md` for the narrative guide and
`specs/11-app-component-catalog.spec.md` for the normative agent contract.
This page is the quick-reference companion used by the `app-component-catalog`
skill.

## Neutral seed role families

Conceptual prompts for gap detection only — rename, merge, split, or drop any
row to match the application's own design system and language.

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

## Reasoning templates

Use these prompts while auditing or generating; answer each in the app's own
terms, not the seed vocabulary's.

- **Gap check** — "Which seed family has no matching app component yet, and is
  that a real gap or an intentional omission?"
- **Alias check** — "Do these two names describe the same purpose and
  behavior, or only a similar appearance?"
- **Variant-vs-drift check** — "Does this difference come from an intentional
  variant rule, or from an undocumented implementation choice?"
- **Reuse-vs-new check** — "Does an existing component satisfy this need if
  extended, or is the user need genuinely distinct?"
- **Placement check** — "Does the candidate's do-not-use, data, or responsive
  rule conflict with this region, page type, or IA level?"

## Logical component entry template

`templates/app-component-catalog/component-entry.md` implements the full
metadata contract in spec 11 §7 (identity, usage, placement, composition,
styling abstractions, data/content, behavior/states, responsive behavior, and
selection metadata). Copy it once per accepted logical component into the
downstream's chosen gallery representation.

## Audit vs. generate, at a glance

| | Audit | Generate |
|---|---|---|
| Starting point | Observed usage + bindings | Audience/task/page context |
| Core action | Group, normalize, classify | Search, eliminate, reuse/extend/specify |
| Output | Evidence-linked findings | New/updated gallery entry + rationale |

## Boundary rules

- A **component** is a reusable logical interface unit.
- A **pattern** is a proven multi-component composition (owned by
  `pattern-library`).
- A **layout** defines page regions (owned by the App Layout Catalog, spec 12,
  once implemented).
- A **page** applies a layout and fills regions with components/patterns.
- An **implementation binding** realizes a logical component; it is never the
  component's complete design contract.

## Example scenarios

See `tests/fixtures/app-component-catalog/` for a worked audit example and a
worked generate example, including sample findings and a sample gallery
entry.
