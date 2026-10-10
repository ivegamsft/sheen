# Incident Learnings Log

Captured operational learnings from build and automation incidents. Keep entries
short, evidence-based, and actionable.

## 2026-09-09 — Complete frontmatter audit and owner-aware follow-up

**Decision record:** audit follow-up, owned by Sheen maintainers for source and
consumer integration, and BaseCoat maintainers for canonical imported assets.
Tracking: [#232](https://github.com/ivegamsft/sheen/issues/232);
upstream work:
[upstream-basecoat#3324](https://github.com/ivegamsft/sheen/issues/3324).
Learning capture is
[#240](https://github.com/ivegamsft/sheen/issues/240). This
record logs findings and decisions, not
implementation approval, release readiness, or completed remediation.

### Audit evidence and recheck boundary

The audit covered 597 actual frontmatter headers and ten fenced examples across
1,311 Markdown files at Sheen commit
`8a92f1c34ceece05f06a62e21eff01f49508601a`: 78 source headers, 143 installed
headers, 373 vendored headers, and three other documentation headers. All 2,293
tracked file prefixes were considered; no non-Markdown frontmatter was found.
Templates, supporting documents, ignored build outputs and runtime entrypoints
were kept distinct. Open PR #231 was not part of the audited snapshot.

Before filing upstream issues, the affected files were rechecked at BaseCoat
commit `4238b033c862c52b0c3cc85059307b89eb1e4489`, rather than treating the
vendored pin `daf83646e67abd6a4e71852917b4acd9fa4075c0` as current upstream.
The security-operations folded tool declaration was already corrected; one of
five duplicate-visibility cases was corrected; the old Sheen upgrade prompt was
absent from both current upstream and the declared vendor pin. Absence alone
does not establish retirement: the prompt's ownership/provenance needs
reconciliation. These cases do not justify duplicate upstream repair issues.

### Frontmatter audit learnings

1. **Valid YAML is necessary, not sufficient.** The snapshot had two YAML parse
   failures and five duplicate-key headers. Another header was valid YAML but
   folded apparent tool-list entries into a visibility string. Use strict
   mapping/duplicate-key parsing and artifact-specific semantic schemas; a
   regex match or successful parse alone does not establish a valid contract.

2. **Removing universal globs does not prove isolation.** Nine Sheen instructions
   still matched every Markdown file, eight matched `server/client/database.py`,
   and navigation matched `server/routes/orders.ts`. The Wave 6 cases below
   established specific positive and negative examples, not exhaustive backend
   exclusion. Expand negative witnesses to nested folders and non-design
   documentation; preserve intentional frontend and downstream paths.

3. **Discovery is a promise about scope and output.** Authoring that returns only
   a governance report, IA vocabulary that invites database modeling, and
   overlapping audit/implementation descriptions create contract ambiguity.
   Define the primary entry point, delegate and requested output, then exercise
   neighboring positive and negative cases. Shared vocabulary alone is not
   proof of a runtime routing failure.

4. **Metadata needs one documented meaning per field.** Twelve source skills
   omitted pillars and used a category outside the documented vocabulary;
   generated metadata preserved twelve null pillars. Imported assets also
   mixed category meanings, discovery tiers, audiences, dependencies and host
   compatibility. Validate the appropriate schema rather than forcing every
   artifact into one field set. Neither `visibility: internal` nor an empty
   tool declaration proves an access-control boundary.

5. **Model declarations are not execution or entitlement evidence.** Source
   agents inherit selection; imported policies mix family aliases and concrete
   identifiers. The source capability catalog and active task-tool descriptors
   need host/surface qualification. Record capability provenance, normalize
   aliases and pin/preference precedence, and distinguish task depth from
   provider effort. Missing catalog entries do not prove unavailable models;
   counts of pins do not establish actual usage, cost or latency.

6. **Follow the distribution path, not just the directory name.** Most vendor
   definitions are reference assets, but `sync.ps1:23` includes vendored prompts
   when syncing the full source. The public publisher removes `vendor/**`.
   Inspect source, sanitized publication and consumer selection separately
   before claiming an artifact is active or harmless. Vendor-only assets need
   explicit ownership and migration/removal decisions that preserve
   consumer-owned edits; missing upstream files are not automatically obsolete.

7. **Recheck upstream and deduplicate by canonical ownership.** The 132 common
   installed/vendor skill headers were identical after normalization. File one
   canonical issue for a shared defect and track both refresh surfaces, rather
   than creating independent repair issues for each copy. Reuse
   [#227](https://github.com/ivegamsft/sheen/issues/227) for the
   existing guide-authoring gap. Preserve closed upstream work while logging
   residual semantic defects that its original acceptance did not cover.
   Compare the declared pin as well as current upstream before claiming a file
   was retired or attributing a local overlay defect to upstream.

8. **An existing green gate only proves its stated coverage.** The source
   frontmatter linter and asset audit passed despite schema and semantic-scope
   gaps. Report population coverage and runtime limitations explicitly. Extend
   existing gates with evidence-shaped cases rather than presenting static
   metadata inspection as verified loader behavior or compliance certification.

### Decisions, alternatives and follow-up

The chosen approach is canonical upstream correction followed by reviewed
installed/vendor refresh, with source-owned fixes kept in Sheen. Direct vendor
patches were rejected because they lose provenance and diverge from upstream.
Blindly filing every snapshot finding upstream was rejected because some were
already corrected or had no verified upstream origin. Broad model replacement
was rejected because no workload/entitlement evidence established that it was
needed.

Sheen maintainers own source scopes, taxonomy, validation and catalog provenance.
BaseCoat maintainers own imported definitions and host contracts. Refresh work
depends on the relevant reviewed upstream fixes; availability claims wait for
separately authorized implementation and consumer evidence. No due dates or
automatic implementation are inferred from this logging request.

### Finding-to-issue traceability

S denotes source findings, I installed findings, and V vendored findings. The
upstream links cover shared installed/vendor defects once, not twice.

| Finding | Follow-up |
|---|---|
| S1 - backend and Markdown scope leakage | [#233](https://github.com/ivegamsft/sheen/issues/233) |
| S2 - categories and twelve missing pillars | [#234](https://github.com/ivegamsft/sheen/issues/234) |
| S3 - authoring/output mismatch | Existing [#227](https://github.com/ivegamsft/sheen/issues/227) under [#225](https://github.com/ivegamsft/sheen/issues/225); specification delivered by [#231](https://github.com/ivegamsft/sheen/pull/231) |
| S4 - ontology scope ambiguity | [#235](https://github.com/ivegamsft/sheen/issues/235) |
| S5 - neighboring review and accessibility-target ambiguity | [#236](https://github.com/ivegamsft/sheen/issues/236) |
| S6 - strict YAML/schema assurance | [#237](https://github.com/ivegamsft/sheen/issues/237) |
| I-01 - Electron agent identifiers in `applyTo` | [upstream-basecoat#3330](https://github.com/ivegamsft/sheen/issues/3330) |
| I-02 - model aliases and precedence | [upstream-basecoat#3331](https://github.com/ivegamsft/sheen/issues/3331) |
| I-03 - conflicting category fields | [upstream-basecoat#3332](https://github.com/ivegamsft/sheen/issues/3332) |
| I-04 - audit/implementation and namespace boundaries | [upstream-basecoat#3333](https://github.com/ivegamsft/sheen/issues/3333) |
| I-05 - contradictory API handoff | [upstream-basecoat#3334](https://github.com/ivegamsft/sheen/issues/3334) |
| I-06 - optional tools versus required dispatch | [upstream-basecoat#3335](https://github.com/ivegamsft/sheen/issues/3335) |
| V1 - two YAML failures | [upstream-basecoat#3325](https://github.com/ivegamsft/sheen/issues/3325) |
| V2 - duplicate visibility | [upstream-basecoat#3326](https://github.com/ivegamsft/sheen/issues/3326) for four remaining cases; [#239](https://github.com/ivegamsft/sheen/issues/239) for the corrected fifth case |
| V3 - folded tool declaration | Already corrected upstream; refresh via [#239](https://github.com/ivegamsft/sheen/issues/239) |
| V4 - UX alias targets Quality | [upstream-basecoat#3327](https://github.com/ivegamsft/sheen/issues/3327) |
| V5 - agent-definition paths used as operational scopes | [upstream-basecoat#3328](https://github.com/ivegamsft/sheen/issues/3328) |
| V6 - upgrade prompt execution/tool mismatch | Absent at current and pinned upstream; reconcile ownership, source sync and consumer remnants via [#239](https://github.com/ivegamsft/sheen/issues/239) |
| V7 - alias distribution mismatch | [upstream-basecoat#3329](https://github.com/ivegamsft/sheen/issues/3329) |
| Host-aware model capability evidence | [#238](https://github.com/ivegamsft/sheen/issues/238) |
| Host schemas and copyable-example advisories | [upstream-basecoat#3336](https://github.com/ivegamsft/sheen/issues/3336) |
| Reviewed installed/vendor refresh | [#239](https://github.com/ivegamsft/sheen/issues/239) |

Prior upstream scope, pointer-stub and negative-clause work remains recorded in
[upstream-basecoat#2975](https://github.com/ivegamsft/sheen/issues/2975),
[upstream-basecoat#2977](https://github.com/ivegamsft/sheen/issues/2977),
[upstream-basecoat#2926](https://github.com/ivegamsft/sheen/issues/2926)
and
[upstream-basecoat#3134](https://github.com/ivegamsft/sheen/issues/3134).
Closed work was not reopened merely because an older vendor snapshot retained
its original problem.

---

## 2026-08-31 — Wave 6 system atlas, instruction scoping, and release

Wave 6 delivered the generated system atlas, two rounds of diagram-rendering
corrections, path-scoped Copilot instructions, and the v0.11.0 source and
production releases. Evidence: #150, #152, #154, #156, #158, and
[v0.11.0](https://github.com/ivegamsft/sheen/releases/tag/v0.11.0).

### Wave 6 learnings

1. **Visual verification must inspect the failing region at deployment-equivalent
   scale.**
   - A full-page local screenshot and static SVG geometry checks passed after the
     first atlas correction, but the deployed treemap still had cramped labels
     and the Sankey labels were misaligned (#152, #154).
   - The reliable check was a focused screenshot of each figure at normal
     desktop scale, followed by direct inspection of every small treemap slice
     and Sankey column.
   - Lesson: overview screenshots prove page composition, not chart legibility.
     Use focused crops or element screenshots for dense visualizations.

2. **Static diagram lints need explicit coverage for text fitting and anchor
   semantics.**
   - Existing geometry and anti-slop checks caught connector and styling defects,
     but did not detect text overflowing a narrow treemap cell or a Sankey label
     anchored on the wrong side of its column.
   - Lesson: renderer changes need data-shaped fixtures and rendered-image
     inspection in addition to markup heuristics.

3. **Path-scoped instructions require executable positive and negative
   contracts.**
   - Frontmatter review alone could confirm that `applyTo` existed, but not that
     UI paths matched or backend, infrastructure, and data paths did not.
   - The Wave 6 contract validates all ten instructions, rejects universal
     scopes, proves representative `.cs`, `.bicep`, `.sql`, backend `.ts`, and
     backend `.js` paths match zero sheen instructions, and confirms a TSX
     component receives the expected design layers (#156).
   - Lesson: treat instruction matching as routing behavior and test both
     inclusion and exclusion.

4. **Source layout and downstream installation layout must be tested together.**
   - The token instruction originally targeted source `tokens/**`, while sync
     installs the same assets under `sheen/tokens/**` in consumer repositories.
   - Lesson: every path-scoped contract must include producer and consumer paths;
     otherwise a locally correct scope can silently fail after sync.

5. **A merged change is not published for pinned consumers.**
   - Wave 6 changes were available on `main`, but production consumers are
     expected to pin release tags. Delivery was not complete until version
     metadata, source release assets, the sanitized production mirror/tag, and
     production docs all reported v0.11.0 (#158).
   - Lesson: use the release and mirror workflows as promotion gates, not
     post-delivery administration.

6. **Apply wave/sprint labels when a PR is opened, not at release time.**
   - The release workflow measures label coverage across the tag window. The six
     post-v0.10 PRs had to be labeled retrospectively before v0.11.0 could pass
     the release gate.
   - Lesson: PR creation is the correct point to assign delivery-wave metadata;
     release preparation should verify labels, not reconstruct them.

### Wave 6 follow-up guardrails

1. For dense SVG changes, capture focused element screenshots in addition to a
   full-page screenshot.
2. Add renderer regression fixtures whenever a defect depends on narrow cells,
   long labels, or multi-column anchor placement.
3. Maintain representative positive and negative paths in
   `scripts/test-instruction-scopes.ps1` whenever an instruction glob changes.
4. Include downstream sync destinations in every path-related contract test.
5. Do not declare a consumer-facing wave complete until the source release,
   production mirror, and production docs workflows are green.
6. Add the applicable `wave:*` or `sprint:*` label when opening each PR.

---

## 2026-08-14 — Dependabot update job failures on skill packages

- **Symptom:** repeated `Dependabot Updates` workflow failures while product CI
  (`Sheen - CI`) stayed green.
- **Signature:** `create_pull_request` returned HTTP 400 with
  `"The request contains invalid or unauthorized changes"` and
  `dependency_file_not_supported`.
- **Blast radius:** dependency automation runs for nested npm manifests under
  `.github/skills/*`; no direct break in compile/test/lint pipelines.
- **Classification:** configuration / automation workflow mismatch.

### Dependabot learnings

1. Split incident triage between product delivery pipelines and maintenance
   automation pipelines before escalating release risk.
2. For Dependabot failures, always capture first failing run URL, first failed
   step, and the first API error block before attempting fixes.
3. Repeated `create_pull_request` 400 responses indicate policy/config/layout
   mismatch, not dependency-resolution instability alone.

### Follow-up guardrails

1. Add/maintain a known-signature entry for this Dependabot 400 pattern in
   runbook or triage docs.
2. Pin package-manager behavior for nested skill packages where dependency
   automation is enabled.
3. Keep dependency automation ownership explicit for `.github/skills/*`.

---

## 2026-08 — Skill implementation and standardization wave

Captured learnings from bulk implementation of 46 BaseCoat skills, full catalog
with agents, token system, and quality audit / hardening cycles.

### Skill-wave learnings

#### Skill contract enforcement and metadata drift

1. **Frontmatter normalization is a contract requirement, not a style preference.**
   - Audit found 8 skills with description lines starting "USE FOR:"/"DO NOT USE FOR:"
     but missing the normalized preface "Use when ...".
   - Impact: inconsistent discovery and routing when tools depend on field parsing.
   - Lesson: Establish frontmatter normalization as CI gate (lint gate now in place);
     catch early before catalog scales.

2. **Cross-platform content hashing requires explicit normalization.**
   - Windows CRLF vs Linux LF line endings produced different SHA-256 hashes for
     identical logical file content.
   - Impact: metadata drift detection failed on cross-platform CI runs until
     normalization was added to `build-metadata.ps1`.
   - Lesson: Always normalize file content (UTF-8, LF) before computing hashes
     for drift detection; don't rely on binary file reads.

#### Skill routing and eval quality

1. **Generic eval scenarios weaken routing confidence.**
   - Initial scenarios ("Help with...", "Need support...") were template-level
     and failed to disambiguate from neighboring skills.
   - Audit found 37 skills with generic prompts lacking domain specificity.
   - Impact: skill router could misclassify requests across overlapping skill scope.
   - Lesson: Extract USE FOR/DO NOT USE FOR phrases from skill description and
     compose realistic positive/negative routing scenarios. Validation should flag
     scenarios that do not reference concrete skill scope.

2. **Eval YAML structure compliance needs automated enforcement.**
   - Contract requires ≥5 scenarios (≥3 positive, ≥2 negative); manual reviews
     caught late violations.
   - Lesson: Lint gate now checks scenario count and structure; enforce at
     commit time, not at audit time.

#### Model capability governance

1. **Model capability declarations must be centralized and versioned.**
   - Skills and agents need to declare supported model IDs, reasoning effort,
     tool support, and context length for accurate capability routing.
   - Initial approach: embed metadata in skill frontmatter only.
   - Better approach: centralized governance artifact (`docs/reference/model-capabilities.json`)
     with ownership, update process, and version history.
   - Lesson: Capability metadata should be: (a) single source of truth, (b) audit-able,
     (c) version-tracked, (d) referenced from skill/agent frontmatter.

#### Delivery flow and governance

1. **Incremental phase execution and validation gates build confidence.**
   - Phases 0–5 were executed sequentially with commit/PR/merge cycle for each.
   - Early validation (tokens, frontmatter lint, metadata drift) caught issues
     before merge.
   - Lesson: gate-per-phase is effective; automate validation early; avoid
     accumulating large branches.

### Skill-wave follow-up guardrails

1. Document model-capabilities.json ownership and update SLA for when new models
   are released or deprecated.
2. Add eval scenario realism scoring to audit tooling (not just count checks).
3. Consider skill-capability matrix export for downstream routing decisions.
