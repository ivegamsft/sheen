---
name: visual-regression
compatibility: [github-copilot-cli]
description: "Use when setting up visual snapshot baselines, triaging visual diffs, or detecting design QA drift. USE FOR: snapshot baseline setup, visual diff triage, design QA drift detection. DO NOT USE FOR: functional test authoring, security threat modeling."
category: governance
metadata:
  category: governance
  maturity: beta
  audience: [designer, developer]
  pillar: governance
allowed-tools: []
---

# visual-regression

Detect and triage unintended visual changes.

## Workflow
1. Define scope, policy, and acceptance criteria; read and apply the [pixel-diff pipeline contract](references/pixel-diff-pipeline.md), including source-checkout prerequisites and baseline procedure.
2. Render target artifacts deterministically (`render-all-diagram-samples.ps1`)
   and screenshot them (`npx playwright test`) against committed baselines.
3. Record non-conformance findings (pixel diffs, CI failures) with severity
   and remediation path.
4. Recommend policy-safe improvements with escalation thresholds; only
   update a baseline for a reviewed, intentional design change.
5. Publish a concise decision log for review and auditability.

## Guardrails
- Do not approve out-of-policy changes without documented exception path.
- Do not hide uncertainty in compliance judgments.
- Do not recommend changes without clear ownership and closure criteria.
- Do not conflate style preference with contractual requirement.
- Do not run `--update-snapshots` to silence a CI failure without a
  reviewed, intentional design change behind it.
- Use the pinned rendering environment and 0.01 pixel-diff ratio; retain the
  corrupted-render check proving real changes are caught.

## Output
- Governance report with findings, severity, and remediation owners.
- Decision log with follow-up checkpoints.
- Playwright HTML report / diff PNGs (`playwright-report/`, uploaded as a
  CI artifact on failure) for visual triage.

## Delegates / pairs with
- design-update
- design-system-audit
- design-review
