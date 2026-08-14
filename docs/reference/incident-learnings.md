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
