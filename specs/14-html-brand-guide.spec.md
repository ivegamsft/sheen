# Spec 14 - HTML Brand Guide Skill

> Status: **Proposed specification only; not an installed skill or renderer.**
> Specification delivery: #223. Implementation requires separate authorization.
> Proposed skill: `brand-guide-html`. Accountable agent: `brand-steward`.

## 1. Purpose and design decision

Generate a navigable, responsive HTML reference guide from approved downstream
guidance, or a clearly unpopulated template when those inputs are unavailable.
The guide explains a system through principles, rules, specimens, application
examples and practical governance. It is not a deck embedded in a web page.

Introduce one narrowly scoped **authoring/composition skill**, not another agent,
identity-design system, theme factory or general presentation converter. Existing
specialists retain authority over their respective decisions. This skill packages
those decisions into a usable reference artifact; it does not silently create or
approve them.

HTML is the requested delivery format. No application framework, package manager,
hosting service, token serialization or downstream repository structure is imposed.
Publishing a guide, changing application styles or applying a new identity requires
separate authorization.

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

### 4.1 Proposed discovery contract

The future skill MUST conform to [Spec 02](02-skill-contract.spec.md), including
an entry body below the unchanged W03 ceiling with mandatory local references.
The following frontmatter is a proposal, not registration:

```yaml
---
name: brand-guide-html
compatibility: [github-copilot-cli]
description: "Generate a reusable HTML brand reference from approved inputs. USE FOR: create an HTML brand guide, build an offline identity handbook, turn approved guidance into a navigable web reference, refresh an existing generated guide. DO NOT USE FOR: inventing an identity, choosing a theme, copying a reference deck, generating reporting dashboards."
category: brand
metadata:
  category: brand
  maturity: draft
  audience: [designer, developer]
  pillar: brand
allowed-tools: []
---
```

The workflow MUST require reading the bundled guide contract and section recipes,
classify the request, separate reference/input channels, map approved evidence,
author HTML, review the rendered artifact and deliver a scoped handoff.

### 4.2 Responsibility boundaries

| Existing owner | Responsibility retained |
|---|---|
| `brand-steward` / `brand-identity` | Identity principles, accepted decisions and consistency |
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

### 5.2 Modes

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

Modes share one module model. They are not separate skills, and refresh does not
authorize changing the application, deleting source assets or publishing output.

## 6. Section system and layout profiles

Each included module MUST have a stable ID, title, concise purpose, applicability,
content status, approved/proposed evidence, and any missing inputs. Where useful,
include a rule, illustrative specimen, annotation, rationale and use/avoid example.
The same rule must not disagree between prose, specimens and application examples.

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

Deliver the HTML artifact or bundle, a module/input status summary, a resource
inventory and a review report. They may share a downstream record format; no
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

## 9. Evaluation and acceptance

Routing scenarios MUST meet Spec 02's existing schema and specificity threshold.
At minimum include these concrete cases:

| Scenario | Expected activation |
|---|---|
| Generate an offline HTML handbook from approved guidance and an authorized asset set | Yes |
| Produce an unpopulated HTML template using only a reference's section structure | Yes |
| Refresh an existing generated guide after an approved typography-role revision | Yes |
| Produce a compact quick-reference version without losing use restrictions | Yes |
| Choose a new application theme from competing candidates | No; `theming` |
| Define a new identity or asset usage policy without guide authoring | No; existing brand specialists |
| Convert a presentation into a pixel-identical slide viewer | No; presentation tooling |
| Build a live revenue dashboard with reporting charts | No; reporting/engineering owners |

Implementation acceptance must exercise generated artifacts and real failure
paths, not merely assert that skill text mentions the right rules:

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

Use entirely synthetic fixtures. No supplied reference deck, screenshot, extracted
text, identity-specific value or original asset may become a fixture or snapshot.
Leakage checks should combine approved-input allowlisting, artifact/resource
inspection and independent review; string matching alone cannot prove that copied
artwork has not been transformed. Local artifact checks and measured browser
evidence must be distinguished from subjective visual review and agent-behavior
evaluation. Do not claim the future skill is implemented from spec-only checks.

## 10. Planned implementation and integration

The implementation should be split into the following bounded tasks. This
specification does not authorize executing them.

| Work item | Deliverable and dependency |
|---|---|
| Skill contract | Concise `SKILL.md`, mandatory guide contract and module/layout recipes; implements sections 3-8 |
| Starter material | Skill-local Markdown outline/input checklist/section recipes with role placeholders; no copied HTML or source assets |
| Routing and composition | `eval.yaml`, `brand-steward` composition, catalog/spec 07, vocabulary/metadata and relevant discovery guidance |
| Artifact authoring | Framework-neutral HTML output process using available downstream tools; no unbundled renderer dependency |
| Evidence and regressions | Synthetic H01-H14 cases, routing cases and browser/manual-review evidence with negative mutations |
| Consumer integration | Whole-folder sync, portable references, explicit output ownership, documentation and tested refresh behavior |

Suggested future shape:

```text
skills/brand-guide-html/
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

HTML is the generated deliverable; Markdown starter recipes preserve the current
Spec 02 template contract. If implementation introduces an executable generator,
it must be independently scoped, justified, tested and bundled with every required
dependency rather than assumed present in consumer repositories.

Implementation MUST retain the existing body budget, full skill-payload metadata,
reference integrity, routing and accessibility handoffs. Do not register this
proposed skill in the live catalog or regenerate metadata to imply availability
during specification delivery. No new version, release or deployment is part of
this specification. Rollout and any output migration belong to the separately
authorized implementation.
