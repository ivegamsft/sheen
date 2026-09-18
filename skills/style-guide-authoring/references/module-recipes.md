# Style guide module recipes

Use these recipes to assemble one guide model across Markdown and the HTML delivery profile. Markdown remains the default deliverable. HTML selection only changes the delivery profile for this skill; portable packaging, byte budgets and offline bundle implementation are available through the skill-local HTML helper. Browser inspection evidence remains a separate readiness input.

## Source precedence

Apply sources by scope in this order: mandatory constraints, approved downstream decisions, current downstream evidence and explicitly requested placeholders. A structural reference may inform section roles only; it is never a source for identity, copy, assets, values, filenames or metadata. Conflicting approved rules for the same scope are BLOCKED. Unapproved or stale derived facts are DRAFT.

## Specialist ownership

`design-reviewer` orchestrates guide assembly and governance handoff. Preserve specialist ownership:

| Area | Owner to cite or request |
|---|---|
| Identity principles and accepted decisions | `brand-identity` / `brand-steward` |
| Reusable patterns and composition | `pattern-library` |
| Logo and approved asset rules | `logo-usage` |
| Voice and example copy | `brand-voice-tone` / `ux-writing` |
| Imagery direction and asset suitability | `imagery-illustration` |
| Semantic roles and theme selection evidence | `design-tokens` / `theming` |
| Taxonomy and findability beyond basic navigation | `information-architecture` |
| Accessibility evidence | `accessibility-audit` / `color-contrast-check` |

Missing specialists or inputs are unresolved dependencies, not permission to invent decisions.

## Baseline modules

Each included module needs a stable ID, title, purpose, applicability, content status, evidence, missing inputs and owner. Mark non-applicable modules with rationale.

| Module | Required content when applicable |
|---|---|
| Guide orientation | Scope, audience, revision, state and navigation |
| Foundations | Purpose, principles and positioning constraints |
| Approved identity assets | Variants, contexts, source references, alternatives and restrictions |
| Usage and constraints | Placement, clear space, minimum size and prohibited treatments |
| Visual foundations | Semantic roles, permitted combinations and evidenced contrast |
| Typography | Role mapping, hierarchy, weights, fallbacks and embedding permission |
| Imagery and illustration | Direction, composition, treatments, permissions and alternatives |
| Voice and messaging | Principles, tone matrix and approved/proposed examples |
| Application patterns | Selected downstream contexts with approved representative content |
| Resources and governance | Owners, revisions, decision state, resources and checklist |

## Layout profiles

- Reference manual (default): flowing sections for ongoing lookup.
- Presentation-inspired: editorial chapters and specimens without fixed slide canvases.
- Quick reference: condensed rules and tables without dropping restrictions or unresolved states.

No layout profile may hide critical restrictions, required context or missing evidence. HTML-specific semantics, print, asset-safety and packaging evidence should be recorded as UNKNOWN or N/A when not implemented or not applicable.
