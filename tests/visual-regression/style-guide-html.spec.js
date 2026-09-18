// @ts-check
const { test, expect } = require('@playwright/test');
const fs = require('fs');
const os = require('os');
const path = require('path');
const { execFileSync } = require('child_process');

const repoRoot = path.join(__dirname, '..', '..');
const scratch = fs.mkdtempSync(path.join(os.tmpdir(), 'sga-browser-'));
const guidePath = path.join(scratch, 'guide.md');
const assetPath = path.join(scratch, 'swatch.png');
const manifestPath = path.join(scratch, 'assets.json');
const selfContainedPath = path.join(scratch, 'self-contained.html');
const bundlePath = path.join(scratch, 'bundle', 'index.html');

function toFileUrl(filePath) {
  return `file://${filePath.replace(/\\/g, '/')}`;
}

test.describe('style-guide-authoring HTML browser acceptance', () => {
  test.beforeAll(() => {
    fs.writeFileSync(
      guidePath,
      [
        '# Browser acceptance',
        '',
        'Intro paragraph with a [local fragment](#assets).',
        '',
        '## Assets',
        '',
        '- Keyboard target',
        '',
        '| Token | Value |',
        '|---|---|',
        '| primary | #0969da |',
        '',
        'AReallyLongUnbrokenTokenNameThatMustWrapAtSmallWidthsWithoutForcingHorizontalViewportOverflow'.repeat(8),
      ].join('\n')
    );
    fs.writeFileSync(
      assetPath,
      Buffer.from(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+/p9sAAAAASUVORK5CYII=',
        'base64'
      )
    );
    fs.writeFileSync(
      manifestPath,
      JSON.stringify({
        assets: [{ id: 'approved-swatch', path: 'swatch.png', mediaType: 'image/png', alt: 'Approved swatch', permission: 'embed' }],
      })
    );

    const cli = path.join(repoRoot, 'skills', 'style-guide-authoring', 'scripts', 'render-html-guide.ps1');
    execFileSync('pwsh', ['-NoProfile', '-File', cli, '-MarkdownPath', guidePath, '-OutputPath', selfContainedPath, '-AssetManifestPath', manifestPath, '-RepoRoot', scratch, '-Quiet'], { stdio: 'inherit' });

    const bundleManifest = path.join(scratch, 'bundle-assets.json');
    fs.writeFileSync(
      bundleManifest,
      JSON.stringify({
        assets: [{ id: 'approved-swatch', path: 'swatch.png', mediaType: 'image/png', alt: 'Approved swatch', permission: 'copy' }],
      })
    );
    execFileSync('pwsh', ['-NoProfile', '-File', cli, '-MarkdownPath', guidePath, '-OutputPath', bundlePath, '-Packaging', 'local-bundle', '-AssetManifestPath', bundleManifest, '-RepoRoot', scratch, '-Quiet'], { stdio: 'inherit' });
  });

  test.afterAll(() => {
    fs.rmSync(scratch, { recursive: true, force: true });
  });

  for (const [name, htmlPath] of [
    ['self-contained', selfContainedPath],
    ['local-bundle', bundlePath],
  ]) {
    test(`${name} loads from file without network or script execution`, async ({ page }) => {
      const externalRequests = [];
      page.on('request', (request) => {
        if (/^https?:/.test(request.url())) externalRequests.push(request.url());
      });
      await page.goto(toFileUrl(htmlPath));
      await expect(page.locator('main')).toContainText('Browser acceptance');
      await expect(page.locator('script')).toHaveCount(0);
      expect(externalRequests).toEqual([]);
    });
  }

  test('keyboard, reflow, and print surfaces are browser-checkable', async ({ page }) => {
    await page.setViewportSize({ width: 320, height: 640 });
    await page.goto(toFileUrl(selfContainedPath));
    await page.keyboard.press('Tab');
    await expect(page.locator('.sga-skip')).toBeFocused();
    const scrollWidth = await page.evaluate(() => document.documentElement.scrollWidth);
    expect(scrollWidth).toBeLessThanOrEqual(320);
    await page.pdf({ format: 'A4' });
    await page.pdf({ format: 'Letter' });
  });
});
