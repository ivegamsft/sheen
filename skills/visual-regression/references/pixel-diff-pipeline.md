# Pixel-Diff Pipeline (#129)

Read before running the workflow or updating baselines. This skill is backed
by a real, CI-enforced pixel-diff pipeline, not only governance prose.
Commands and paths below are relative to a sheen source checkout, not a
standalone synced skill folder; obtain the source assets via these links:

- [Batch renderer](https://github.com/ivegamsft/sheen/blob/main/scripts/render-all-diagram-samples.ps1)
  and [diagram renderer](https://github.com/ivegamsft/sheen/blob/main/scripts/render-diagram.ps1)
- [Samples](https://github.com/ivegamsft/sheen/tree/main/skills/documentation-diagram/samples)
- [Playwright test](https://github.com/ivegamsft/sheen/blob/main/tests/visual-regression/diagrams.spec.js),
  [baselines](https://github.com/ivegamsft/sheen/tree/main/tests/visual-regression/diagrams.spec.js-snapshots),
  [config](https://github.com/ivegamsft/sheen/blob/main/playwright.config.js),
  and [CI](https://github.com/ivegamsft/sheen/blob/main/.github/workflows/ci.yml)

## Render, compare, and prove detection

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

## Reviewed baseline updates only

- **Updating baselines** after an intentional design change: render, then
  run `npm run test:visual:update` inside the same Playwright container
  (`docker run --rm -v "${PWD}:/work" -w /work
  mcr.microsoft.com/playwright:v1.62.1-jammy npx playwright test
  --update-snapshots`) and commit the updated PNGs with a rationale in the
  PR description — never update a baseline to hide an unreviewed
  regression.
