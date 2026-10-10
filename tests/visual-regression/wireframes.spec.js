// @ts-check
const { test, expect } = require('@playwright/test');
const fs = require('fs');
const os = require('os');
const path = require('path');
const { pathToFileURL } = require('url');
const { execFileSync } = require('child_process');

const root = path.join(__dirname, '..', '..');
const skill = path.join(root, 'skills', 'wireframing');
const python = process.platform === 'win32' ? 'python' : 'python3';
let scratch;
let output;
let svgOutput;

test.describe('wireframe click-through acceptance', () => {
  test.beforeAll(() => {
    scratch = fs.mkdtempSync(path.join(os.tmpdir(), 'wireframe-browser-'));
    output = path.join(scratch, 'prototype.html');
    execFileSync(python, [
      path.join(skill, 'scripts', 'render-wireframes.py'),
      '--input', path.join(skill, 'templates', 'task-flow.json'),
      '--format', 'html', '--output', output,
    ]);
    svgOutput = path.join(scratch, 'storyboard.svg');
    execFileSync(python, [
      path.join(skill, 'scripts', 'render-wireframes.py'),
      '--input', path.join(skill, 'templates', 'task-flow.json'),
      '--format', 'svg', '--output', svgOutput,
    ]);
  });

  test.afterAll(() => {
    fs.rmSync(scratch, { recursive: true, force: true });
  });

  test('keyboard/mouse, focus, states, back/reset and no network', async ({ page }) => {
    const errors = [];
    const requests = [];
    page.on('pageerror', error => errors.push(error.message));
    page.on('console', message => { if (message.type() === 'error') errors.push(message.text()); });
    page.on('request', request => { if (!request.url().startsWith('file:')) requests.push(request.url()); });
    await page.goto(pathToFileURL(output).href);
    await expect(page.getByRole('heading', { name: 'No saved views' })).toBeFocused();
    await page.screenshot({ path: test.info().outputPath('wireframe-start.png'), fullPage: true });
    await page.keyboard.press('Tab');
    await expect(page.getByRole('link', { name: 'Create view' })).toBeFocused();
    await page.keyboard.press('Enter');
    await expect(page.getByRole('heading', { name: 'Name the view' })).toBeFocused();
    await page.getByLabel('View name (sample only)').fill('Sample');
    await page.getByRole('link', { name: 'Preview save error' }).click();
    await expect(page.getByRole('heading', { name: 'Save error example' })).toBeFocused();
    await page.getByRole('button', { name: 'Back', exact: true }).click();
    await expect(page.getByLabel('View name (sample only)')).toHaveValue('Sample');
    await page.getByRole('link', { name: 'Save sample view' }).click();
    await expect(page.getByRole('heading', { name: 'View saved', exact: true })).toBeFocused();
    await page.getByRole('button', { name: 'Reset prototype' }).click();
    await expect(page.getByRole('button', { name: 'Back', exact: true })).toBeDisabled();
    await page.getByRole('link', { name: 'Create view' }).click();
    await expect(page.getByLabel('View name (sample only)')).toHaveValue('');
    expect(errors).toEqual([]);
    expect(requests).toEqual([]);
    expect(await page.evaluate(() => localStorage.length)).toBe(0);
  });

  test('all modeled actions resolve and narrow layout does not overflow', async ({ page }) => {
    const model = JSON.parse(fs.readFileSync(path.join(skill, 'templates', 'task-flow.json'), 'utf8'));
    for (const screen of model.screens) {
      for (const block of screen.regions.flatMap(region => region.blocks).filter(block => block.kind === 'action')) {
        await page.goto(pathToFileURL(output).href + '#' + screen.id);
        await page.getByRole('link', { name: block.label, exact: true }).click();
        await expect(page.locator(`[data-screen="${block.target}"]`)).toBeVisible();
      }
    }
    await page.setViewportSize({ width: 320, height: 640 });
    for (const screen of model.screens) {
      await page.goto(pathToFileURL(output).href + '#' + screen.id);
      expect(await page.evaluate(() => document.documentElement.scrollWidth)).toBeLessThanOrEqual(320);
    }
  });

  test('unknown routes are visible and reset recovers', async ({ page }) => {
    await page.goto(pathToFileURL(output).href + '#unknown');
    await expect(page.getByRole('alert')).toBeVisible();
    await page.getByRole('button', { name: 'Reset prototype' }).click();
    await expect(page.getByRole('alert')).toBeHidden();
    await expect(page.getByRole('heading', { name: 'No saved views' })).toBeFocused();
  });

  test('SVG is a readable static board with no clipped text or executable content', async ({ page }) => {
    await page.goto(pathToFileURL(svgOutput).href);
    await expect(page.locator('svg')).toHaveAttribute('role', 'img');
    await expect(page.locator('script')).toHaveCount(0);
    const clipped = await page.locator('svg').evaluate(svg => {
      const bounds = svg.viewBox.baseVal;
      return Array.from(svg.querySelectorAll('text')).some(text => {
        const box = text.getBBox();
        return box.x < 0 || box.y < 0 || box.x + box.width > bounds.width || box.y + box.height > bounds.height;
      });
    });
    expect(clipped).toBe(false);
    await page.screenshot({ path: test.info().outputPath('wireframe-storyboard.png') });
  });
});
