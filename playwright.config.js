// @ts-check
const { defineConfig, devices } = require('@playwright/test');

/**
 * Visual regression config for sheen's rendered diagram output (#129).
 *
 * Targets are static, self-contained HTML files produced by
 * scripts/render-diagram.ps1 (one per skills/documentation-diagram/samples/*.json
 * spec). Rendering happens as a pre-test step (scripts/render-all-diagram-samples.ps1),
 * not inside Playwright itself, so the browser only ever screenshots
 * deterministic, already-built markup.
 *
 * Baselines are committed under tests/visual-regression/diagrams.spec.js-snapshots/.
 * To intentionally update them after a deliberate design change, run:
 *   npm run test:visual:update
 */
module.exports = defineConfig({
  testDir: './tests/visual-regression',
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 1 : 0,
  reporter: process.env.CI ? [['list']] : [['html', { open: 'never' }]],
  outputDir: 'test-results',
  expect: {
    toHaveScreenshot: {
      // Small tolerance for anti-aliasing/font-rendering drift across
      // environments while still catching real layout/color regressions.
      maxDiffPixelRatio: 0.01,
    },
  },
  use: {
    trace: 'retain-on-failure',
  },
  projects: [
    {
      name: 'chromium',
      use: { ...devices['Desktop Chrome'] },
    },
  ],
});
