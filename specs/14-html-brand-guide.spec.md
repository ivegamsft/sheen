# Spec 14 - Guide Authoring and HTML Delivery

> Status: **Proposed extension; the existing skill does not implement this contract.**
> Original specification: #223. Reuse correction: #226; implementation epic: #225.
> Existing skill: `style-guide-authoring`. Proposed orchestration: `design-reviewer`.
> Implementation requires separate authorization; no new skill or renderer is added.

## 1. Purpose and design decision

Assemble a complete reference guide from approved downstream guidance, or a
clearly unpopulated template when those inputs are unavailable. Preserve Markdown
as the default authoring format and support HTML when explicitly requested.
The guide explains a system through principles, rules, specimens, application
examples and practical governance. It is not a deck embedded in a web page.

Extend the existing **`style-guide-authoring` skill**, not another agent,
authoring skill, identity-design system, theme factory or presentation converter.
This supersedes the original `brand-guide-html` new-skill decision in #223/#224.
Do not register that name or introduce a parallel alias. Existing specialists
retain authority over their decisions; guide assembly does not create or approve
them. Existing governance-only requests must remain report-only operations.

HTML is a delivery profile, not a separate content-authoring workflow. No application
framework, package manager, hosting service, token serialization or downstream
repository structure is imposed.
Publishing a guide, changing application styles or applying a new identity requires
separate authorization.

### 1.1 Existing capability and logged gaps

The original comparison omitted the closest existing authoring skill and templates.
HTML publication through a docs platform already exists as guidance; portable
offline generation with the contracts below is the proposed enhancement.

| Existing asset | Reuse and correction |
|---|---|
| [`style-guide-authoring`](../skills/style-guide-authoring/SKILL.md) | Retain name, governance category and report-only requests; repair the workflow/output mismatch so authoring actually returns a guide (#227) |
| [Catalog authoring contract](07-skill-catalog.spec.md#governance--meta) | Already promises a complete guide; reconcile implementation with that promise rather than adding a competing catalog entry (#227) |
| [Brand guide template](../templates/brand-guidelines/README.md) | Reuse section purposes, approval flow and resource organization; placeholders and template examples are not approved downstream decisions (#228) |
| [Style guide template](../templates/style-guide/README.md) | Retain guide compilation, Markdown/docs-platform publication and existing section coverage (#227, #228) |
| [`DESIGN.md` generator](../scripts/build-design-md.ps1) | Consume current derived mechanical facts when available; do not require the source-only generator in a copied skill (#228) |
| [`AESTHETIC-DIRECTION.md` generator](../scripts/build-aesthetic-direction.ps1) | Consume approved creative direction with provenance; generation does not confer approval (#228) |
| [`pattern-library`](../skills/pattern-library/SKILL.md) | Retains reusable pattern definition and composition; guide assembly references its results rather than duplicating its mandate (#227) |

The remaining gaps are the actual HTML artifact process and bounded packaging
(#229), plus freshness, compatibility and consumer-delivery evidence (#228, #230).
Reference isolation, accessible output, print, safe content and readiness are
retained requirements, not newly discovered omissions. Reporting diagrams remain
outside scope.

## 2. Structural review and web adaptation

The structural review covered the reference's 14-page sequence, editable content
roles and object organization through local read-only inspection. It was not a
pixel-fidelity assessment. Only the following abstract teaching patterns inform
this specification; no reference-specific examples or visual values are retained.

| Observed structural pattern | Reusable HTML treatment |
|---|---|
| Opening identity and purpose context | Guide masthead, scope, audience and orientation |
| Rules followed by usage constraints | Rule/specimen panels with explicit annotations and rationale |
| Foundation sections before applications | Progressive navigation from principles to detailed guidance |
| Distinct typography, imagery and verbal sections | Separately addressable modules with reusable specimen layouts |
| Repeated application/reference panels | A configurable application gallery rather than fixed slide copies |
| Closing resources and governance | Ownership, revision, approval status and usable resource references |

The web requirements below are **new requirements**, not claims that the reference
already provides them: responsive reflow, stable deep links, semantic structure,
keyboard operation, accessible alternatives, offline operation, print styles,
missing-input states, asset safety and evidence-backed readiness.

Do not preserve a fixed 14-page count, exact slide dimensions, coordinates,
decorative geometry, proprietary wording or an implied list of supported channels.
Preserve the instructional progression, not the presentation's visual expression.

## 3. Reference isolation and source precedence

Reference material and output-authoring inputs MUST be treated as separate
information channels.

1. A structural reference MAY inform generic section roles and teaching patterns.
2. Only independently supplied, approved downstream decisions and authorized
   assets MAY populate the output's identity, specimens and usage examples.
3. A reference supplied as a template MUST NOT become an asset or value source,
   even when a needed downstream input is missing.

Reference-derived identity, marks, palette values, typeface choices, copy, images,
screenshots, vector artwork, filenames, author/company properties, comments,
speaker notes, hidden slides and embedded metadata MUST NOT appear in generated
HTML, styles, scripts, alt text, captions, asset paths, reports, examples, issues
or implementation fixtures. Renaming or recoloring a copied asset does not make
it an independently authored asset. Do not embed a screenshot of the reference.

Where comparison is necessary, inspect the reference locally through authorized
read-only access. Do not bypass protection, upload it to a conversion service or
persist its extracted content, deny lists or fingerprints. A local isolation check
may report a category and pass/fail outcome, never the prohibited value itself.
If access is unavailable, report that the reference was not reviewed; do not
invent its contents.

Output precedence is: mandatory constraints, approved downstream decisions,
current downstream evidence, explicitly requested placeholders. Conflicting
approved rules for the same scope block populated-guide readiness until their
owner resolves them; do not choose arbitrarily. Framework
defaults do not constitute an approved downstream identity.

## 4. Activation and ownership

### 4.1 Proposed extension to the existing discovery contract

The updated skill MUST conform to [Spec 02](02-skill-contract.spec.md), including
an entry body below the unchanged W03 ceiling with mandatory local references.
The following frontmatter is proposed replacement wording, not a live update.
Preserving the existing stable maturity label does not claim the HTML profile is
available before implementation:

```yaml
---
name: style-guide-authoring
compatibility: [github-copilot-cli]
description: "Compile or review guides from approved guidance. USE FOR: style-guide compilation, pattern library publication, guideline consolidation, author an offline HTML guide, refresh a generated guide, check guide freshness. DO NOT USE FOR: single-component-only specs, token validation scripts, inventing an identity, choosing a theme, copying a reference deck, generating reporting dashboards."
category: governance
metadata:
  category: governance
  maturity: stable
  audience: [designer, developer]
  pillar: governance
allowed-tools: []
---
```

The workflow MUST require reading the bundled guide contract and applicable
section recipes, classify intent and delivery format, separate reference/input
channels, map approved evidence, perform only the selected operation, and deliver
its scoped outputs. An audit must not become an authoring or publication request.

### 4.2 Responsibility boundaries

| Existing owner | Responsibility retained |
|---|---|
| `style-guide-authoring` / `design-reviewer` | One guide-assembly workflow and governance handoff; add the skill to agent composition only during implementation |
| `brand-steward` / `brand-identity` | Identity principles, accepted decisions and consistency |
| `pattern-library` | Definition and composition of reusable patterns consumed by the guide |
| `logo-usage` | Rules for independently supplied approved identity assets |
| `brand-voice-tone` / `ux-writing` | Verbal principles, context-sensitive tone and example copy |
| `imagery-illustration` | Image direction, permitted treatments and asset suitability |
| `design-tokens` / `theming` | Semantic role mappings and approved theme selections |
| `information-architecture` | Guide taxonomy and findability when more than basic navigation is needed |
| `accessibility-audit` / `color-contrast-check` | Applicable accessibility review and evidence |
| `app-layout-catalog` | Existing downstream layout decisions when relevant |
| `documentation-diagram` | Separately requested supported explanatory diagrams, never reporting |

Implementation MUST verify these installed capabilities by their actual catalog
names and available contracts. Missing delegates are unresolved dependencies,
not an invitation to invent a successful handoff. Existing agent composition and
routing must be updated only when this skill is implemented.

The skill does not replace Experience Blueprint, app component/layout catalogs,
theme selection, presentation editing, a general UI audit or frontend engineering.
It may consume their approved results without assuming they exist.

### 4.3 Compatibility and output selection

Separate request intent (audit, template, generation, refresh or freshness check)
from delivery format (Markdown or HTML) and from layout/packaging profiles.
For authoring, use an explicit format first, then the existing guide's format for
refresh, otherwise Markdown. Do not create both formats unless requested.

Existing governance reviews continue to return findings, severity, remediation
owners and a decision log. Authoring MUST return the actual guide, not a report
claiming that one was written. Preserve existing template-based Markdown and
docs-platform workflows; HTML is additive, not an automatic migration.

Retain the established `metadata.style_guide_url` and `metadata.brand_guide_url`
publication conventions without writing either during generation or check.
Record a proposed URL only as a handoff; publishing and configuration changes
require separate authorization. No upload, hosted service or new runtime is implied.

## 5. Inputs and operating modes

### 5.1 Logical input record

These concepts may come from existing documents or tool results; a new registry
or JSON schema is not required.

| Input | Required behavior |
|---|---|
| Scope and audience | Identify the guide's purpose, audience, language and intended uses |
| Approved guidance | Preserve revision, decision status and permitted evidence references per module |
| Visual and verbal roles | Use downstream semantic mappings and approved content, not reference-derived defaults |
| Asset set | Identify local source, permitted use/embedding, purpose, alternatives and status |
| Module selection | Mark each proposed module included, not applicable or awaiting input, with rationale |
| Layout and packaging profile | Select the profiles in sections 6 and 7; record deviations |
| Output boundary | Explicit destination and permission to create/replace named artifacts |
| Existing guide, if refreshing | Record current revision, stable section IDs and ownership boundaries |
| Review context | Target browsers/viewports, offline/print needs and available review evidence |
| Packaging budget | Final-byte limits, selected packaging and any explicitly authorized override (section 7.1) |

Approved-input provenance MUST record a permitted source identifier, scope,
immutable revision or content digest, approval status/evidence, and the module/rule it
supports. Record sufficient guide-owned artifact and input revision evidence for
refresh/check; an existing downstream record format is acceptable. Never store
structural-reference contents, identifiers or fingerprints in this record.
Revision evidence must identify the actual content read, including local changes;
a matching repository commit does not attest to a modified working file.

### 5.2 Input discovery and precedence

Discover within the authorized downstream scope; do not crawl unrelated files
or require a particular directory. Reuse applicable existing guides and templates
before proposing new sections. Record the mapping below, or an equivalent
downstream source with the same semantics; these filenames are not prerequisites.

| Source | Treatment |
|---|---|
| Approved downstream guides and decisions | Authority for approved guidance in their stated scope; preserve source revisions and restrictions |
| Native tokens and semantic role mappings | Mechanical source of truth when designated by the downstream owner; do not infer approval from a token's existence |
| `DESIGN.md` or equivalent | Derived mechanical evidence; compare with its designated source when available and report discrepancies |
| `AESTHETIC-DIRECTION.md` or equivalent | Narrative input subject to independent approval; not authority to override mechanical facts or approved constraints |
| Existing guide templates | Structural recipes and placeholders only; do not promote example rules, filenames or assets to approved guidance |
| Approved component/layout/pattern records | Reuse application guidance and stable references instead of redefining the same decisions |

Apply section 3 precedence by scope, not simply by filename or most recent
timestamp. Two contradictory approved rules for the same scope are BLOCKED.
Unapproved or stale derived guidance is DRAFT until resolved, not a license to
rewrite the approved source. Missing provenance is UNKNOWN evidence.

Source reconciliation MUST NOT run generators, edit tokens or approve narrative
decisions implicitly. A missing named artifact is acceptable when approved
equivalent evidence is available; without sufficient evidence the affected module
remains unresolved. Portable skill-local recipes must not depend on top-level
repository templates being installed.

### 5.3 Modes

**Audit:** Review the supplied guide against its applicable contracts. Return the
existing governance report and decision log without writing guide artifacts,
refreshing inputs or publishing. A report-only request does not require HTML.

**Template:** Produce an original neutral shell, labeled `TEMPLATE`, with
role-based placeholders and an input checklist. Use labels such as
`{{guide_title}}`, `{{approved_asset}}` and `{{semantic_role}}`, not fabricated
organizations, palette samples, typeface selections or invented approvals.
The shell's presentation is illustrative, not an approved identity.

**Generate:** Populate included modules from approved inputs. Missing decisions
stay explicitly unresolved; do not borrow from the structural reference. Proposed
copy or application examples must be labeled as proposals and require the
appropriate downstream review before they can count as approved guidance.

**Refresh:** Compare input revisions and update only authorized guide-owned
artifacts. Preserve stable section IDs and consumer-owned additions. Report removed
sections, changed rules and missing assets. Require an explicit replacement
boundary when ownership is unclear; do not overwrite a hand-authored guide.
If inputs, profile and owned content are unchanged, refresh MUST be a no-op:
do not rewrite files, reorder sections or churn timestamps. Detect unexpected
edits to owned content; require an explicit reconciliation boundary rather than
silently overwriting them. Approved changed content invalidates prior review
evidence for affected checks until reassessed.

**Check:** Read an existing guide, its permitted provenance/ownership evidence and
current authorized inputs without modifying guide files, sources, metadata or
timestamps. Report freshness as CURRENT, STALE or UNKNOWN. CURRENT requires
matching recorded source revisions/digests and owned-artifact evidence, not just
matching version labels or file dates. Changed inputs or unexpected artifact
edits are STALE; unavailable comparison evidence is UNKNOWN. Enumerate affected
modules and suggested actions; do not regenerate to make the check pass.

Freshness and readiness are independent: CURRENT is not approval or accessibility
evidence. STALE/UNKNOWN prevents a populated guide from being assessed READY.
Report the current assessment without mutating an embedded historical label.
Known unsafe content or unresolved ownership conflicts still produce BLOCKED.
The skill contract defines reports, not a fictional command or exit code.

Modes share one module model. They are not separate skills, and refresh does not
authorize changing the application, deleting source assets or publishing output.

## 6. Section system and layout profiles

Each included module MUST have a stable ID, title, concise purpose, applicability,
content status, approved/proposed evidence, and any missing inputs. Where useful,
include a rule, illustrative specimen, annotation, rationale and use/avoid example.
The same rule must not disagree between prose, specimens and application examples.
The inventory below is a baseline, not a reason to discard applicable sections
from an existing guide. Retain spacing/layout, motion, accessibility, component
indexes and changelog content as stable modules or subsections where applicable.
Markdown and HTML use the same approved content and status model; layout choices
must not silently narrow its scope.

| Module | Required content when applicable | Reusable presentation pattern |
|---|---|---|
| Guide orientation | Scope, audience, revision, status and navigation | Editorial cover and compact metadata |
| Foundations | Purpose, principles and positioning constraints | Overview plus principle cards |
| Approved identity assets | Approved variants, contexts and asset references | Accessible specimen gallery |
| Usage and constraints | Placement, clear space, minimum size and prohibited treatments | Annotated specimen and paired use/avoid panels |
| Visual foundations | Semantic appearance roles, permitted combinations and evidenced contrast | Role table and input-driven specimens |
| Typography | Approved role mapping, hierarchy, weights, fallbacks and permitted embedding | Type specimen and hierarchy table |
| Imagery and illustration | Direction, composition, treatments, permissions and alternatives | Annotated example grid |
| Voice and messaging | Principles, context-specific tone and approved/proposed examples | Tone matrix and paired examples |
| Application patterns | Selected downstream channels and representative approved content | Repeatable preview plus specification panel |
| Resources and governance | Owners, revisions, decision state, permitted resources and checklist | Resource list and handoff/checklist panel |

Application patterns MAY cover presentation, product, web, communication, print
or other downstream-approved contexts. Do not infer a channel from the reference
or require every example type. Missing approved artwork remains a labeled asset
slot, not a broken image. A resource link must resolve or be visibly unavailable;
do not provide decorative download buttons with no resource.

Three profiles share this model:

| Profile | Use | Layout behavior |
|---|---|---|
| Reference manual (default) | Detailed ongoing lookup | Section navigation and flowing article modules |
| Presentation-inspired | Guided introduction or stakeholder reading | Editorial chapters with generous specimens, not fixed-size slide canvases |
| Quick reference | Compact working checklist | Condensed rules and tables, preserving constraints and unresolved states |

No profile may hide critical restrictions, required context or missing evidence
to appear complete. Small screens use one logical reading order; wide layouts may
place rule and specimen side by side. Print keeps essential content and status.

## 7. HTML artifact contract

This section applies when HTML is selected. Markdown remains a supported
authoring deliverable and uses its existing docs-platform presentation; HTML-only
packaging and browser checks must not become mandatory for a Markdown-only request.
Reference isolation, source safety, approval and ownership rules apply to both.

### 7.1 Packaging

Default output is one self-contained HTML document with embedded styles, safe
authorized assets where feasible, and no mandatory JavaScript. A local bundle
is an explicit alternative for larger authorized assets: entry HTML and clearly
named relative dependencies with no server or build step required for reading.
Paths are downstream-selected; `docs/brand-guide/index.html` is an example only.

All content and navigation MUST work from the local file and without JavaScript.
No remote fonts, tracking, analytics, automatic downloads, remote asset fetches,
CDN dependencies or embedded presentation viewers. External resource references
may be ordinary clearly identified links, not automatically fetched dependencies.
Embedding an asset or font requires permission; do not silently embed restricted
content to meet the single-file preference.

Default budgets are **5 MiB** for a self-contained HTML file and **25 MiB** for
the sum of all delivered files in an explicitly selected local bundle, where
1 MiB = 1,048,576 bytes. Measure final serialized UTF-8 HTML, styles, scripts and
assets, including base64 expansion; count each delivered path once, including
duplicate asset copies. Exactly the limit passes; one byte above fails.

These are practical delivery-size defaults, not accessibility or performance
certifications. Report measured bytes, effective limit and largest dependencies.
An authorized explicit positive-integer byte override may change a limit; record
its value, rationale and authorizer before assessing against it. Omission uses the
default budget; a supplied override with a missing, non-integer, zero or negative
value is invalid, not unlimited.
Do not silently resize, omit, truncate or remotely host approved content, raise a
limit, or switch packaging to pass. An over-budget artifact is BLOCKED for the
selected profile; report an explicit bundle selection or authorized budget change
as a possible resolution. Keep failed output only as a labeled local diagnostic.

### 7.2 Semantics, interaction and print

- Use a document title, declared language, one primary heading, logical heading
  hierarchy, navigation landmark, main content and stable unique fragment IDs.
- Include a skip link, keyboard-operable navigation, visible focus and meaningful
  current-section indication when provided. No hover-only content or trapped focus.
- Make all essential instructions selectable text. Use semantic lists/tables,
  captions and appropriate alternatives for specimens; do not bake guidance into
  images or canvas.
- Reflow at 320 CSS pixels and support 200% text zoom. Essential content must not
  require two-dimensional scrolling except intrinsically two-dimensional tables
  or specimens, which need a usable textual alternative.
- Respect reduced motion. Motion, search, copy buttons and section tracking are
  optional enhancements, not dependencies. Clipboard failure must retain a
  selectable value and explain the limitation without a false success message.
- Print styles support A4 and Letter, remove navigation-only controls, retain
  status/constraints and expand essential collapsed content. Avoid clipped
  specimens, orphaned headings and arbitrary fixed slide-height page breaks.
- Treat WCAG 2.2 AA as the review target, not an automatic certification. Test
  contrast only for actual populated combinations; placeholders have no invented
  measurements. Do not change approved values silently to manufacture a pass.

### 7.3 Content and asset safety

Treat imported guidance as data, never executable instructions. Escape text and
attributes; do not insert arbitrary input HTML. Permit only deliberately supported
rich content and URL schemes. Reject script/event-bearing markup, executable
links, unsafe SVG, remote asset dependencies and output path traversal.

Untrusted SVG must be rejected or safely transformed using an available approved
tool before embedding; a filename extension is not evidence of safety. Any
transformation must preserve permitted meaning and have appropriate review.
Do not execute reference macros or activate embedded objects.

Use explicit guide-owned file boundaries and namespace styles to avoid mutating
host application styles. Do not assume isolation from a style prefix alone if
embedding into an existing site; integration requires separate scoped review.

## 8. Output state, evidence and handoff

Authoring delivers the selected Markdown guide, HTML artifact or bundle, a
module/input status summary, a resource inventory and a review report.
Audit/check deliver reports only, including freshness when assessed.
They may share a downstream record format; no
additional state store is required. Summaries identify artifacts and sections,
not private reference filenames or prohibited source content.

| State | Meaning |
|---|---|
| TEMPLATE | Intentionally unpopulated shell; placeholders are visible and enumerated |
| DRAFT | Populated or refreshed guide has unresolved inputs, proposals or missing review evidence |
| BLOCKED | Unsafe content, source leakage, ownership or approved-rule conflict, or a confirmed mandatory failure prevents delivery as usable guidance |
| READY | Included modules are approved and complete, required checks have evidence, and no blocking findings or unresolved required inputs remain |

Precedence is BLOCKED, then explicit template mode, then DRAFT, otherwise READY.
A template cannot be promoted merely because its HTML parses. Not-applicable
modules require rationale and are not counted as passing checks. Proposed content
and unknown evidence cannot receive READY. READY describes the reviewed artifact
and conditions, not publication, legal clearance beyond supplied approvals,
application adoption or proof of universal accessibility.

Each required review check records PASS, FAIL, UNKNOWN or N/A with scope,
rationale and evidence. An unexecuted browser or assistive-technology check is
UNKNOWN, not PASS. Report known limitations and identify checks needing specialist
review. Failed output may be retained only as a clearly marked local diagnostic
artifact, never published or represented as approved guidance.
Select checks by format and scope: an HTML-only check on Markdown is N/A with a
rationale, not a pass and not an unexplained UNKNOWN. Existing governance reports
remain reports; a successful audit alone does not produce or publish a READY guide.

## 9. Evaluation and acceptance

Routing scenarios MUST meet Spec 02's existing schema and specificity threshold.
At minimum include these concrete cases:

| Scenario | Expected activation |
|---|---|
| Generate an offline HTML handbook from approved guidance and an authorized asset set | Yes |
| Produce an unpopulated HTML template using only a reference's section structure | Yes |
| Refresh an existing generated guide after an approved typography-role revision | Yes |
| Produce a compact quick-reference version without losing use restrictions | Yes |
| Compile existing approved guidance into a Markdown style guide without publishing | Yes; authoring, Markdown |
| Review this style guide for non-conformance and return findings only | Yes; audit, no artifact writes |
| Check whether this generated guide is stale without changing any files | Yes; check, read-only |
| Define a new reusable interaction pattern without assembling a guide | No; `pattern-library` |
| Choose a new application theme from competing candidates | No; `theming` |
| Define a new identity or asset usage policy without guide authoring | No; existing brand specialists |
| Convert a presentation into a pixel-identical slide viewer | No; presentation tooling |
| Build a live revenue dashboard with reporting charts | No; reporting/engineering owners |

Implementation acceptance must exercise generated artifacts and real failure
paths, not merely assert that skill text mentions the right rules. H01-H14 are
retained; HTML-specific cases apply to that profile, not to Markdown-only output:

| ID | Required evidence |
|---|---|
| H01 | Approved-input guide populates every included module from the stated input revision |
| H02 | Template mode has visible, enumerated placeholders and never claims READY |
| H03 | Missing/proposed decisions remain DRAFT; contradictory approved rules for the same scope produce BLOCKED |
| H04 | Refresh preserves consumer additions and stable IDs; ambiguous ownership blocks writes |
| H05 | Synthetic reference-only text/assets/metadata cannot enter visible or hidden output surfaces |
| H06 | Independent input changes alter output appropriately; replacing a structural reference does not import its identity |
| H07 | Browser network capture shows no automatic remote requests; all essential content works with JavaScript disabled |
| H08 | Local bundle resources and fragment links resolve; unavailable assets use explicit slots rather than broken images |
| H09 | Keyboard, heading/landmark, alternative-text and 320-pixel/zoom checks produce recorded evidence |
| H10 | A4/Letter print inspection preserves complete content, status and restrictions |
| H11 | Unsafe markup, URLs, SVG and path inputs fail visibly without execution or unrelated writes |
| H12 | Clipboard/search enhancements degrade safely without hiding content or reporting false success |
| H13 | Confirmed failures and unexecuted checks cannot result in READY; N/A requires rationale |
| H14 | A copied complete skill folder works without private references or source-only tooling |
| H15 | Existing governance requests return reports without writes; default authoring emits Markdown; explicit HTML and refresh format selection follow section 4.3 |
| H16 | Existing templates and approved native/derived sources map to modules; conflicting approved rules block, stale/unapproved facts remain unresolved, and approved equivalents work without named generator artifacts |
| H17 | Unchanged refresh leaves files byte-identical with unchanged timestamps; unexpected owned edits are not overwritten; changed input invalidates affected review evidence |
| H18 | Each packaging profile passes exactly at its effective byte limit and fails one byte above; base64/duplicate-file accounting, explicit positive overrides, rejected invalid overrides and no silent fallback are exercised |
| H19 | Check reports CURRENT/STALE/UNKNOWN accurately, including unchanged labels with changed contents; no guide/source/metadata writes occur and freshness alone never promotes readiness |
| H20 | Markdown retains applicable original guide sections; HTML-only checks are N/A; publication and URL metadata changes never occur without separate authorization |
| H21 | Routing, agent composition, catalog and full payload agree on the existing skill name; no duplicate skill/alias appears and copied-folder recipes do not require source templates |

Use entirely synthetic fixtures. No supplied reference deck, screenshot, extracted
text, identity-specific value or original asset may become a fixture or snapshot.
Leakage checks should combine approved-input allowlisting, artifact/resource
inspection and independent review; string matching alone cannot prove that copied
artwork has not been transformed. Local artifact checks and measured browser
evidence must be distinguished from subjective visual review and agent-behavior
evaluation. Do not claim the proposed extension is implemented from spec-only checks.

## 10. Planned implementation and integration

The implementation should be split into the following bounded tasks. This
specification does not authorize executing them.

| Work item | Deliverable and dependency |
|---|---|
| #226 - specification correction | This document and linked indexes; closes only the specification child, not implementation epic #225 |
| #227 - authoring contract and compatibility | Existing `SKILL.md`, local guide contracts, Markdown/audit outputs, `eval.yaml`, `design-reviewer` composition and coherent catalog/discovery updates; depends on #226 |
| #228 - canonical inputs and freshness | Portable recipes adapted from existing templates, source/module provenance, revision-aware refresh and read-only check; depends on #226 and #227 |
| #229 - HTML artifact profile | Framework-neutral HTML authoring, final-byte budget accounting, explicit packaging and safe offline/print output; depends on #226, #227 and #228 |
| #230 - evidence and consumer integration | Synthetic H01-H21, routing/behavior evidence, rendered/manual checks, negative mutations, whole-folder sync and availability documentation; depends on #226 through #229 |

Suggested future shape:

```text
skills/style-guide-authoring/
  SKILL.md
  eval.yaml
  references/
    guide-contract.md
    module-and-layout-recipes.md
    review-checklist.md
  templates/
    guide-outline.md
    input-checklist.md
    section-recipe.md
```

Markdown or HTML is the selected generated deliverable; Markdown starter recipes
preserve the current Spec 02 template contract. Adapt the existing template
section structure rather than maintaining competing canonical guides. If
implementation introduces an executable generator,
it must be independently scoped, justified, tested and bundled with every required
dependency rather than assumed present in consumer repositories.

Implementation MUST retain the existing body budget, full skill-payload metadata,
reference integrity, routing and accessibility handoffs. Do not register this
proposed extension in the live catalog or regenerate metadata to imply availability
during specification delivery. Keep the canonical filename stable to preserve
existing specification links. No new version, release or deployment is part of
this specification. Rollout and any output migration belong to the separately
authorized implementation.
