# Canonical guide inputs and freshness (#228)

Defines the permitted source model for `style-guide-authoring` inputs and the
read-only freshness check. Read this alongside `guide-contract.md` and
`module-recipes.md`. It does not add a new required schema; it names the
concepts those references already use so provenance stays consistent and
testable.

## Permitted source kinds

| Kind | Canonical role | Permitted status | Example source ID |
|---|---|---|---|
| `approved-guide` | Existing approved brand-guidelines/style-guide guide or downstream decision; authority for its stated scope | `APPROVED`, `PROPOSED` | `guide:brand-identity-decisions` |
| `token` | Native design token; mechanical source of truth only when the downstream owner designates it | `APPROVED`, `DERIVED` | `tokens:semantic-color` |
| `derived` | `DESIGN.md`, `AESTHETIC-DIRECTION.md` or an equivalent derived artifact; narrative facts still require independent approval | `DERIVED` | `design-md`, `aesthetic-direction-md` |
| `template` | `templates/brand-guidelines` / `templates/style-guide`; a structural recipe only | `TEMPLATE` | `template:brand-guidelines` |
| `placeholder` | Explicitly requested placeholder, template mode only | `PROPOSED` | `placeholder:guide-title` |

A structural reference or template is never a value, asset or identity source
(spec 14 section 3); it may only inform section roles. Generated guidance
(anything produced by this skill, `DESIGN.md` or `AESTHETIC-DIRECTION.md`) is
never auto-approved by its own existence — approval is a separate, recorded
decision by the owning specialist. Source-only generator scripts (for example
`scripts/build-design-md.ps1`) are convenient but MUST NOT be required in a
downstream/copied skill folder; an equivalent approved artifact with the same
scope and evidence satisfies the same module (H16).

Source IDs and `equivalentFor` target IDs must match
`^[A-Za-z0-9][A-Za-z0-9._:-]*\z`. This delimiter-safe grammar lets refresh
emit IDs into Markdown table cells and comma-separated ownership-marker source
attributes without escaping or corrupting guide boundaries.

## Scope and status vocabulary

Scope values are the module IDs from `module-recipes.md`'s baseline table
(`orientation`, `foundations`, `identity-assets`, `usage-constraints`,
`visual-foundations`, `typography`, `imagery-illustration`, `voice-messaging`,
`application-patterns`, `resources-governance`). Status is one of `APPROVED`,
`PROPOSED`, `DERIVED`, `UNKNOWN`, or `TEMPLATE`. A revision is an immutable
content digest (for example `sha256:<hex>`) or an externally tracked
approval revision string; a matching repository commit does not attest to a
modified working file (spec 14 section 5.1) — always read current content.

## Precedence and conflict handling

Apply section 3's precedence by scope: mandatory constraints, approved
downstream decisions, current downstream evidence (tokens, `DESIGN.md`),
then explicitly requested placeholders. Two `APPROVED` sources recording
different values for the same scope and rule are **BLOCKED**; do not choose one
arbitrarily and do not average or merge them. `DERIVED` and `PROPOSED` keep
authoring readiness in **DRAFT** until an owner approves the resulting
guidance, but freshness is assessed independently: unchanged evidence may be
`CURRENT`, while changed or unavailable evidence is `STALE` or `UNKNOWN`.
Never promote generated evidence to `APPROVED` by generation alone. Missing
provenance for a required module is UNKNOWN evidence, not an invented pass.
The Module status table accepts exactly `included`, `not applicable`, or
`awaiting input`; `not applicable` rows must include a non-empty rationale in
`Missing or proposed items`, and `awaiting input` rows remain `UNKNOWN` until
the table is promoted to `included` or `not applicable`. Malformed rows,
duplicate/repeated module status evidence, and status typos fail closed instead
of silently excluding modules from freshness assessment.

## Read-only freshness check

`scripts/check-guide-freshness.ps1` (or an equivalent host-provided check)
compares a guide's recorded "Approved inputs" table and guide-owned regions
against a current-inputs manifest. It only reads files; it never writes the
guide, its sources, or any metadata/timestamp. Per-module and overall state
is one of:

| State | Meaning |
|---|---|
| `CURRENT` | Every recorded source revision matches its current value and every guide-owned region's recorded content digest matches its current content |
| `STALE` | A recorded source revision or an owned region's content digest no longer matches current evidence |
| `UNKNOWN` | A recorded source has no current authorized counterpart and no approved equivalent |
| `BLOCKED` | Two approved sources conflict for the same scope, or content is unsafe |

Overall state uses `BLOCKED` > `STALE` > `UNKNOWN` > `CURRENT` precedence.
For included canonical modules, approved-input provenance alone is insufficient:
without that module's guide-owned artifact evidence, freshness remains `UNKNOWN`.
When the guide's Module status table explicitly marks included modules, that
selection determines which canonical modules participate in freshness and
require owned-artifact evidence only when the table covers the full canonical
module set; otherwise the check remains fail-closed and uses Approved inputs.
Manifest record errors and incomplete conflict-comparison metadata are scoped to
the modules or source IDs referenced by the guide; unrelated manifest entries do
not degrade an otherwise current guide.
`CURRENT` is never approval, accessibility evidence, or a promotion to
`READY` by itself (spec 14 section 5.3). Refresh (`scripts/refresh-guide.ps1`)
reuses this assessment but remains fail-closed: a fully `CURRENT` guide is a
byte-for-byte, timestamp-preserving no-op, while `STALE` or `UNKNOWN` evidence
returns `PARTIAL` without writing guide content, provenance, or metadata. A
separately authorized regenerator must update owned content and evidence before
reassessment can become `CURRENT`. Consumer-owned
content outside stable `<!-- guide-owned:ID ... --> ... <!-- /guide-owned:ID -->`
markers remains untouched.