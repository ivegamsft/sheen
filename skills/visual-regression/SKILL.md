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

## Implementation (#129)

This skill is backed by a real, CI-enforced pixel-diff pipeline, not only
governance prose:

- **Render**: `scripts/render-all-diagram-samples.ps1` batch-renders every
  `skills/documentation-diagram/samples/*.json` spec to static HTML via
  `scripts/render-diagram.ps1` (#113).
- **Screenshot + diff**: `tests/visual-regression/diagrams.spec.js`
  (Playwright) loads each rendered HTML file headless and asserts
  `expect(page).toHaveScreenshot()` against a committed baseline in
  `tests/visual-regression/diagrams.spec.js-snapshots/`
  (`maxDiffPixelRatio: 0.01`, see `playwright.config.js`).
- **CI gate**: the `visual-regression` job in `.github/workflows/ci.yml`
  runs inside the pinned `mcr.microsoft.com/playwright:v1.62.1-jammy`
  container (so Chromium's font/rendering stack matches the environment
  baselines were generated in), renders all 16 samples, runs the Playwright
  suite, then re-runs it against an intentionally-corrupted render to prove
  the diff still catches real changes — mirroring the broken-fixture
  pattern used by `lint-diagram-geometry.ps1` (#118) and
  `audit-diagram-slop.ps1` (#115).
- **Updating baselines** after an intentional design change: render, then
  run `npm run test:visual:update` inside the same Playwright container
  (`docker run --rm -v "${PWD}:/work" -w /work
  mcr.microsoft.com/playwright:v1.62.1-jammy npx playwright test
  --update-snapshots`) and commit the updated PNGs with a rationale in the
  PR description — never update a baseline to hide an unreviewed
  regression.

## Workflow
1. Define governed scope, policy expectations, and acceptance criteria.
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

## Output
- Governance report with findings, severity, and remediation owners.
- Decision log with follow-up checkpoints.
- Playwright HTML report / diff PNGs (`playwright-report/`, uploaded as a
  CI artifact on failure) for visual triage.

## Delegates / pairs with
- design-update
- design-system-audit
