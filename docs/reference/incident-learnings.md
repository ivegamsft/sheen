# Incident Learnings Log

Captured operational learnings from build and automation incidents. Keep entries
short, evidence-based, and actionable.

## 2026-08-14 — Dependabot update job failures on skill packages

- **Symptom:** repeated `Dependabot Updates` workflow failures while product CI
  (`Sheen - CI`) stayed green.
- **Signature:** `create_pull_request` returned HTTP 400 with
  `"The request contains invalid or unauthorized changes"` and
  `dependency_file_not_supported`.
- **Blast radius:** dependency automation runs for nested npm manifests under
  `.github/skills/*`; no direct break in compile/test/lint pipelines.
- **Classification:** configuration / automation workflow mismatch.

### What we learned

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

### What we learned

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

3. **Generic eval scenarios weaken routing confidence.**
   - Initial scenarios ("Help with...", "Need support...") were template-level
     and failed to disambiguate from neighboring skills.
   - Audit found 37 skills with generic prompts lacking domain specificity.
   - Impact: skill router could misclassify requests across overlapping skill scope.
   - Lesson: Extract USE FOR/DO NOT USE FOR phrases from skill description and
     compose realistic positive/negative routing scenarios. Validation should flag
     scenarios that do not reference concrete skill scope.

4. **Eval YAML structure compliance needs automated enforcement.**
   - Contract requires ≥5 scenarios (≥3 positive, ≥2 negative); manual reviews
     caught late violations.
   - Lesson: Lint gate now checks scenario count and structure; enforce at
     commit time, not at audit time.

#### Model capability governance

5. **Model capability declarations must be centralized and versioned.**
   - Skills and agents need to declare supported model IDs, reasoning effort,
     tool support, and context length for accurate capability routing.
   - Initial approach: embed metadata in skill frontmatter only.
   - Better approach: centralized governance artifact (`docs/reference/model-capabilities.json`)
     with ownership, update process, and version history.
   - Lesson: Capability metadata should be: (a) single source of truth, (b) audit-able,
     (c) version-tracked, (d) referenced from skill/agent frontmatter.

#### Delivery flow and governance

6. **Incremental phase execution and validation gates build confidence.**
   - Phases 0–5 were executed sequentially with commit/PR/merge cycle for each.
   - Early validation (tokens, frontmatter lint, metadata drift) caught issues
     before merge.
   - Lesson: gate-per-phase is effective; automate validation early; avoid
     accumulating large branches.

### Follow-up guardrails

1. Document model-capabilities.json ownership and update SLA for when new models
   are released or deprecated.
2. Add eval scenario realism scoring to audit tooling (not just count checks).
3. Consider skill-capability matrix export for downstream routing decisions.
