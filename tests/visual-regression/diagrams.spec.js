// @ts-check
const { test, expect } = require('@playwright/test');
const fs = require('fs');
const path = require('path');

/**
 * Visual regression for sheen's documentation-diagram renders (#129).
 *
 * Each of the 16 diagram types kept in scope by ADR-006
 * (docs/decisions/adr-006-diagram-scope.md) is rendered ahead of time by
 * scripts/render-all-diagram-samples.ps1 to static, self-contained HTML
 * (via scripts/render-diagram.ps1, #113). This spec loads each rendered
 * file directly from disk and screenshots it, diffing against the
 * committed baseline in diagrams.spec.js-snapshots/.
 *
 * Run locally:
 *   pwsh scripts/render-all-diagram-samples.ps1
 *   npm run test:visual
 *
 * Update baselines after an intentional design change:
 *   npm run test:visual:update
 */

const renderDir =
  process.env.DIAGRAM_RENDER_DIR ||
  path.join(__dirname, '..', '..', 'dist', 'documentation-diagram-out');
const samplesDir = path.join(__dirname, '..', '..', 'skills', 'documentation-diagram', 'samples');

const sampleNames = fs
  .readdirSync(samplesDir)
  .filter((f) => f.endsWith('.json'))
  .map((f) => path.basename(f, '.json'))
  .sort();

test.describe('documentation-diagram visual regression', () => {
  test.beforeAll(() => {
    if (!fs.existsSync(renderDir)) {
      throw new Error(
        `Rendered diagram directory not found: ${renderDir}\n` +
          'Run scripts/render-all-diagram-samples.ps1 before this suite (see SKILL.md).'
      );
    }
  });

  for (const name of sampleNames) {
    test(`${name} matches baseline screenshot`, async ({ page }) => {
      const htmlPath = path.join(renderDir, `${name}.html`);
      if (!fs.existsSync(htmlPath)) {
        throw new Error(
          `Missing rendered output for '${name}': ${htmlPath}\n` +
            'Run scripts/render-all-diagram-samples.ps1 first.'
        );
      }
      await page.goto(`file://${htmlPath.replace(/\\/g, '/')}`);
      await expect(page).toHaveScreenshot(`${name}.png`, { fullPage: true });
    });
  }
});
