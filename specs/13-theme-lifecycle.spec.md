# Spec 13 - App-Specific Theme Lifecycle Contract

> Normative target behavior for comparable theme previews, scoped selection,
> application readiness, and custom-theme generation and revision.
>
> Status: **Draft v0.1 - proposed; implementation tracked by #190 and #191-#195.**
> This document does not claim that the lifecycle enhancements are implemented.

## 1. Purpose and decision

Extend the existing `theming` skill so a downstream agent can audit, compare,
select, generate, and safely apply an application-specific theme. A theme is
a coherent mapping of visual roles to the downstream design system, not just
a named palette or heading/body font pair.

The design decision is to compose existing skills rather than introduce a
new theme-factory skill, agent, preset collection, or implementation platform.
The lifecycle MUST support four enhancements:

1. comparable previews and candidate discovery;
2. traceable selection records and reuse of applicable approved decisions;
3. application readiness and impact review;
4. custom-theme generation, reuse, revision, and post-application review.

Audit and generation MUST use the same logical concepts. Audit MUST document
observed usage and findings without changing target artifacts unless changes
are separately authorized.

## 2. Implementation neutrality and non-goals

The contract governs reasoning, evidence, relationships, and outcomes. It
MUST NOT prescribe a downstream language, framework, token serialization,
repository path, registry schema, gallery tool, renderer, or preview medium.
Sheen's own token assets remain subject to Spec 01; this contract does not
replace that contract or require every downstream artifact to use its format.

The feature MUST NOT introduce:

- fixed theme names, palettes, fonts, or another product's visual identity;
- mandatory PDF showcases or mandatory screenshots as the only evidence;
- reporting diagrams, chart generation, or a dashboard reporting pipeline;
- global brand replacement, new component behavior, or layout redesign;
- mandatory human confirmation for every reuse of an approved selection;
- a runtime theme-application adapter platform or implicit deployment rights.

Existing app dashboards and control towers MAY be preview surfaces; their
data/reporting semantics remain outside this lifecycle.

## 3. Source precedence and constraints

The agent MUST begin with:

1. the downstream's accepted brand, design system, and product decisions;
2. current artifact evidence and applicable theme selections;
3. Experience Blueprint audience, page, flow, and operating-context needs;
4. app-specific component/layout catalogs and platform conventions;
5. neutral discovery aids and exploratory directions.

Accessibility, permitted font use, privacy, and other mandatory constraints
apply throughout; source precedence MUST NOT excuse violating them. If an
accepted brand conflicts with a mandatory criterion, the agent MUST record
the conflict and seek resolution under downstream policy, not silently
replace the brand or declare the result ready.

Missing evidence MUST remain explicit. Preview content MUST be representative
and safe to disclose; sensitive production data MUST NOT be needed to compare
themes or be sent to an unapproved rendering service.

## 4. Logical records

These are required concepts, not required files or schemas. A downstream MAY
store them together or separately and MAY reuse its existing records.

### 4.1 Theme candidate

Each candidate MUST identify:

- stable app-specific identity, revision, name, and concise purpose;
- audience/context, use/do-not-use guidance, and rationale;
- source decisions, provenance, predecessor/base theme when applicable;
- mapped visual roles, typography roles, and intentional exceptions;
- supported target surfaces, modes, states, and known limitations;
- preview evidence and its conditions;
- lifecycle condition and unresolved constraints.

A candidate MUST distinguish visual expression from the semantics of a
component, layout, status, or interaction. Theme selection MUST NOT change
those semantics merely to make a preview more attractive.

### 4.2 Decision, readiness, and application records

Selection MUST reference an exact candidate revision and target scope.
Readiness MUST reference the selection, applicable requirements, findings,
and evidence. Application MUST reference both the readiness outcome and
the downstream authorization to change the target.

The agent MUST keep the following distinctions:

| Condition | Meaning |
|---|---|
| Proposed | Candidate exists; no accepted selection is implied. |
| Selected | An authorized decision chose a revision for a defined scope. |
| Ready | Mandatory readiness requirements pass for that revision and scope. |
| Applied | Authorized changes were made; review is still required. |
| Reviewed | Post-application evidence supports the recorded outcome. |
| Superseded | A later decision/revision replaces this one for specified use. |
| Blocked | Unresolved constraints prevent the next lifecycle step. |

These are logical conditions, not a mandated state-machine implementation.
A failed review MAY coexist with an applied condition; the agent MUST NOT
erase that history or label the failed application complete.

## 5. Comparable previews and discovery

Theming MUST offer discovery by purpose, audience/context, supported
surface/mode, maturity or decision status, and known limitations.

When comparing candidates, the agent MUST:

1. establish the target artifact, platform, required modes, and content set;
2. use the same representative content and comparable conditions for every
   candidate, documenting any unavoidable difference;
3. include the relevant hierarchy, dense text, headings, actions, feedback,
   and constrained-space cases rather than only an idealized hero;
4. cover relevant interactive states for interactive targets and mark
   inapplicable states explicitly for static documents;
5. include required modes such as dark or high contrast when the target
   requires them, rather than imposing a universal fixed mode set;
6. show identity, revision, rationale, limitations, and evidence status beside
   each candidate;
7. record which previews are rendered, simulated, or unrendered.

Typography/content samples SHOULD expose long labels, localization expansion,
required scripts, numeric/code text where relevant, and fallback behavior.
All candidates MUST be judged against the same criteria; a preview MUST NOT
hide a failed state or unsupported mode to improve its apparent quality.

If preview tools are unavailable, the agent MAY produce a logical comparison
and explicitly unverified preview plan. It MUST NOT claim visual readiness.
Required visual evidence remains blocking until supplied through a supported
downstream mechanism. The agent MUST NOT silently install tools or fonts.

## 6. Scoped selection and approval reuse

A selection record MUST include:

- chosen identity/revision and target surfaces, modes, and contexts;
- decision rationale and rejected alternatives when alternatives were assessed;
- evidence references, constraints, exceptions, and unresolved questions;
- decision authority/source and status under downstream policy;
- the previous decision it replaces, if any;
- conditions that trigger reassessment.

The agent MUST reuse an approved selection without a redundant prompt when
its revision, scope, constraints, and required evidence remain applicable.
Selection MUST NOT be inferred from an attractive preview or silence.
Where downstream policy delegates the decision to an agent, that policy MAY
serve as authority; this specification adds no universal human-approval gate.

Material uncertainty SHOULD be resolved through `design-debate`. The agent
MUST NOT manufacture alternatives for an unchanged, already approved choice.
Conflicting or absent decision authority MUST leave selection pending while
non-destructive proposals may continue.

Changes to theme revision, scope, brand constraints, target capabilities, or
required evidence MUST trigger an applicability review. Reuse requires a
recorded finding that the decision remains valid; otherwise the affected
selection/readiness MUST be reassessed before application.

## 7. Readiness and impact review

Readiness MUST be assessed before applying changes and MUST cover:

| Area | Required evidence |
|---|---|
| Semantic mapping | Candidate-to-existing-role mapping; unresolved roles and collisions. |
| Target capability | Supported rendering/application mechanism and unsupported expressions. |
| Typography | Availability, permitted use, weights/styles, scripts, fallbacks, content fit. |
| Accessibility | Applicable criteria, evaluated pairs/states/modes, measurements, findings. |
| Impact | Affected surfaces, component/layout references, exceptions, migration scope. |
| Recovery | Previous accepted state, recovery intent, and downstream change mechanism. |

The agent MUST preserve existing semantic keys. A missing semantic concept
MUST be surfaced and delegated to `design-tokens` under the downstream's
conventions rather than silently invented by `theming`.

Accessibility evidence MUST distinguish normal and large text, applicable
non-text boundaries/focus indicators, and meaningful non-color cues. For
applicable WCAG AA criteria, normal text requires at least 4.5:1 and large
text at least 3:1; applicable non-text visual information requires 3:1.
Exemptions and stricter downstream criteria MUST be recorded explicitly.
Passing palette pairs alone MUST NOT be presented as whole-artifact WCAG
conformance. Rendered backgrounds, states, and target behavior still matter.

Font fallback MUST be reviewed for both role preservation and content fit;
a substituted font is not automatically equivalent. Unknown permitted use
or missing mandatory glyph/weight coverage MUST remain unresolved until an
acceptable font or authorized fallback is established.

Readiness outcomes MUST distinguish pass, fail, unknown, and justified
not-applicable evidence. Failed or unknown mandatory requirements block
readiness. Visual selection or approval MUST NOT override a mandatory gate.

## 8. Application and custom-theme lifecycle

For generation or application, the agent MUST:

1. inspect existing approved themes and decisions;
2. reuse a suitable theme, extend it when its semantic purpose remains valid,
   or justify creation for an unmet need;
3. ground new expression in the app brief and accepted design system through
   `design-exploration` and relevant brand/typography specialists;
4. populate the candidate and comparable previews;
5. record the selection under section 6;
6. complete readiness and impact review under section 7;
7. apply or hand off only the authorized scope through supported downstream
   mechanisms, preserving unrelated content, behavior, and structure;
8. review representative affected surfaces and required modes/states;
9. record actual changes, evidence, exceptions, unresolved findings, and
   migration/recovery guidance.

Custom themes MUST use the same contracts as existing themes. A friendly name
MAY aid discovery but MUST NOT substitute for role mappings or evidence.

Selection and readiness alone do not authorize writing files or deploying.
Where implementation is outside the current task or unavailable, the output
MUST be a bounded handoff rather than a claim of applied changes.

Partial application or post-application failure MUST record which targets
changed, which did not, the remaining risk, and a recovery path. Recovery
MUST respect downstream authorization and MUST NOT overwrite unrelated work.
Repeating application to an unchanged, reviewed target MUST not create
unnecessary changes.

Revisions MUST preserve predecessor and selection history, identify affected
consumers, and invalidate relevant stale evidence. Reassessment MAY be
bounded to affected surfaces when that scope is justified.

## 9. Audit and ownership boundaries

Audit MUST inventory observed theme usage, map it to known candidates and
decisions, identify uncovered surfaces/states, and distinguish legitimate
variants from drift. Findings MUST carry evidence, confidence, impact,
affected artifacts, and recommended action. Absence of a preview or decision
record is not proof that a theme is absent from the application.

| Owner | Responsibility |
|---|---|
| `theming` | Lifecycle coordination, overrides, cross-theme completeness, impact summary. |
| `brand-identity` | Brand authority, identity constraints, distinctiveness guidance. |
| `design-exploration` / `design-debate` | Grounded candidates and resolution of uncertain directions. |
| `typography` / `font-mapping` | Type roles, font inventory/mappings, fallback and fit evidence. |
| `design-tokens` | Semantic definitions and token integrity; not aesthetic selection alone. |
| `color-contrast-check` / `accessibility-audit` | Criterion-level contrast evidence and broader accessibility when needed. |
| `design-review` / `visual-regression` | Representative-content review and available rendered comparison evidence. |
| `design-handoff` / `design-to-code` | Bounded implementation handoff or authorized realization. |

The design-system architect remains the theming composition owner. Experience
Blueprint (Spec 10) MUST reference the selected theme/revision and applicable
decision/evidence rather than reproduce the theme catalog. Component and
Layout Catalogs (Specs 11-12) retain their logical semantics and supply impact
references. This work MUST NOT create duplicate catalogs inside the blueprint.

## 10. Acceptance scenarios

Implementation MUST demonstrate the following outcomes using worked examples
and existing evaluation facilities. Routing activation tests alone do not
prove lifecycle behavior or visual quality.

| ID | Scenario | Required outcome |
|---|---|---|
| T01 | Compare two candidates | Same representative content/conditions; differences and limitations visible. |
| T02 | Interactive versus static target | Relevant states covered; inapplicable states justified without fabricated interaction. |
| T03 | Preview mechanism unavailable | Logical comparison allowed; visual claims withheld and required evidence blocked. |
| T04 | Existing approved selection reused | No redundant confirmation; revision/scope/evidence applicability recorded. |
| T05 | Revision or scope changes | Stale decision/readiness reassessed before application. |
| T06 | Brand conflict or missing authority | Conflict/pending status recorded; no silent replacement or invented approval. |
| T07 | Font unavailable or incomplete | Permitted fallback reviewed for scripts/weights/fit, or readiness blocked. |
| T08 | Contrast failure in one required state | Affected pair/criterion reported; selection does not bypass the gate. |
| T09 | Target cannot express a mapped role | Explicit limitation and resolution/handoff; no success-shaped substitution. |
| T10 | Application partially fails | Actual changed targets and recovery intent recorded; completion withheld. |
| T11 | Custom theme requested | Reuse/extend/create justified; ordinary preview/selection/readiness gates retained. |
| T12 | Accepted theme revised | History preserved, affected consumers identified, stale evidence reassessed. |
| T13 | Audit legitimate variants and drift | Evidence-backed distinction; no target changes without authorization. |
| T14 | Brand-only or reporting-only request | Route to existing owner; do not trigger broad theme application. |

## 11. Implementation breakdown

Parent epic: [#190](https://github.com/IBuySpy-Shared/basecoat-sheen/issues/190).

| Issue | Deliverable | Depends on |
|---|---|---|
| [#191](https://github.com/IBuySpy-Shared/basecoat-sheen/issues/191) | Comparable preview/discovery contract, examples, routing coverage. | Reviewed Spec 13. |
| [#192](https://github.com/IBuySpy-Shared/basecoat-sheen/issues/192) | Scoped selection record, approval reuse, reassessment examples. | #191 candidate identity contract. |
| [#193](https://github.com/IBuySpy-Shared/basecoat-sheen/issues/193) | Readiness evidence, impact/recovery review, bounded application handoff. | #192 selection contract. |
| [#194](https://github.com/IBuySpy-Shared/basecoat-sheen/issues/194) | Custom generation/revision and existing-theme audit integration. | #191-#193. |
| [#195](https://github.com/IBuySpy-Shared/basecoat-sheen/issues/195) | Integrated scenarios, routing boundaries, downstream guidance. | #191-#194. |

Shared skill ownership favors sequential integration over independent edits to
the same skill. Supporting contracts/examples MAY live in existing skill
references or templates to preserve skill-body budgets. No new skill, runtime
dependency, test framework, or metadata category is required by this spec.

## 12. Definition of done

The enhancement is complete when all scenarios in section 10 have explicit
expected outcomes and evidence, downstream guidance describes both supported
and blocked paths, and existing routing boundaries remain intact.

Any executable fixture representation MUST be described as illustrative, not
a mandatory downstream schema. Documentation MUST distinguish proposed
behavior from implemented capability. Updated implementation assets MUST use
existing repository checks and regenerate related metadata/catalog/atlas
artifacts when those assets change.

This specification PR creates the contract and backlog only. It MUST NOT
close the epic or implementation issues merely because the spec is published.
