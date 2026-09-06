# Incident Learnings Log

Captured operational learnings from build and automation incidents. Keep entries
short, evidence-based, and actionable.

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
