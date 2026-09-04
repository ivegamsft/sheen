# Experience Archetypes

> Reasoning templates, not finished themes or fixed sitemaps (spec §7). An
> archetype declares required user outcomes and moments; it never prescribes
> brand styling, a color palette, or a specific component library.

## The eight initial archetypes

| Archetype ID | Primary optimization | Required moments |
|---|---|---|
| `marketing-home` | Explain value and establish trust | hero, proof, benefits, conversion, footer |
| `campaign-splash` | Focus attention on one message or action | message, proof, primary action, legal |
| `commerce` | Find, compare, select, and purchase | discovery, detail, cart, checkout, confirmation |
| `dashboard` | Monitor status and act on summarized information | overview, drill-down, filters, alerts, empty/error |
| `control-tower` | Detect, prioritize, coordinate, and resolve operations | situation view, queue, detail, action, escalation |
| `workflow-app` | Complete a multi-step business task | start, progress, validation, review, completion |
| `docs-knowledge` | Find, understand, and apply information | browse, search, article, related content, feedback |
| `admin-settings` | Configure policy and preferences safely | overview, categories, edit, validation, audit history |

## Composing archetypes

1. Select one **primary** archetype that names the dominant outcome.
2. Add **supporting** archetypes only for outcomes the primary archetype does
   not cover (for example: `commerce` primary + `dashboard` and
   `admin-settings` supporting, for a commerce administration product).
3. Merge required moments from every selected archetype into the page/flow
   inventory — do not drop a required moment because it is inconvenient.
4. Note any moment a supporting archetype normally requires but this product
   intentionally omits, and record the rationale as a decision (not a gap).

## Declaring a custom archetype

A custom archetype MUST declare:

| Field | Description |
|---|---|
| Archetype ID | Stable, kebab-case, unique once published |
| User outcome | The one-sentence job it optimizes |
| Required moments | Moments that MUST be represented by a page or flow |
| Optional moments | Moments that MAY be represented |
| Default navigation/layout tendencies | Non-binding starting guidance only |
| Characteristic risks and anti-patterns | What commonly goes wrong |
| Compatibility | Which other archetypes it can/cannot compose with |

It MUST NOT declare brand styling, tokens, or runtime components. Custom
archetype IDs are stable once published — replacing one requires a
deprecation period (spec §14).

## Validation

Every required moment for every selected archetype MUST resolve to at least
one page or flow ID in the experience index (`experience-index.md` §3).
`scripts/audit-experience-blueprint.ps1` reports an archetype's required
moments that are not represented.
