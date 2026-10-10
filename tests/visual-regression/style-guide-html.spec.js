// @ts-check
const { test, expect } = require('@playwright/test');
const fs = require('fs');
const path = require('path');
const { pathToFileURL, fileURLToPath } = require('url');
const { execFileSync } = require('child_process');
const { deflateSync } = require('zlib');
const { inventory, assessEvidence, recordCheck } = require('./style-guide-evidence');

const repoRoot = path.join(__dirname, '..', '..');
const python = process.platform === 'win32' ? 'python' : 'python3';
const pdfInspector = path.join(__dirname, 'style-guide-print.py');
const requiredChecks = ['offline', 'keyboard', 'reflow320', 'textZoom200', 'printA4', 'printLetter'];
const contentSelector = 'h1,h2,h3,h4,h5,h6,p,li,blockquote,th,td,figcaption';

async function finalizeEvidence(report, required, output, close, attach) {
  const failures = report.runFailure ? [new Error(report.runFailure)] : [];
  const appendFailure = (error) => {
    failures.push(error);
    report.runFailure = failures.map(String).join('\n');
  };
  try {
    await close();
  } catch (error) {
    appendFailure(error);
  }
  const persist = (pending = false) => fs.writeFileSync(output, JSON.stringify({ ...report,
    browserReview: pending && !report.runFailure ? 'UNKNOWN' : assessEvidence(report, required),
    finalization: pending ? 'attachment-pending' : 'complete' }, null, 2));
  // Attach a conservative snapshot: an attachment API can copy before throwing.
  persist(true);
  try {
    await attach(output);
  } catch (error) {
    appendFailure(error);
  }
  persist();
  if (failures.length) throw new AggregateError(failures, failures.map(String).join('\n'));
}

// An original raster specimen with enough area to measure decoding and print bounds.
function specimenPng(alternate = false) {
  const chunk = (type, data) => {
    const payload = Buffer.concat([Buffer.from(type), data]);
    let crc = 0xffffffff;
    for (const byte of payload) {
      crc ^= byte;
      for (let bit = 0; bit < 8; bit++) crc = (crc >>> 1) ^ ((crc & 1) ? 0xedb88320 : 0);
    }
    const length = Buffer.alloc(4);
    length.writeUInt32BE(data.length);
    const checksum = Buffer.alloc(4);
    checksum.writeUInt32BE((crc ^ 0xffffffff) >>> 0);
    return Buffer.concat([length, payload, checksum]);
  };
  const header = Buffer.alloc(13);
  header.writeUInt32BE(160, 0);
  header.writeUInt32BE(80, 4);
  header[8] = 8;
  header[9] = 2;
  const pixels = Buffer.alloc(80 * (1 + 160 * 3));
  for (let y = 0; y < 80; y++) {
    for (let x = 0; x < 160; x++) {
      const offset = y * 481 + 1 + x * 3;
      pixels.set(alternate ? (x < 80 ? [170, 45, 75] : [190, 220, 240]) :
        (x < 80 ? [36, 85, 110] : [230, 218, 196]), offset);
    }
  }
  return Buffer.concat([
    Buffer.from('89504e470d0a1a0a', 'hex'),
    chunk('IHDR', header), chunk('IDAT', deflateSync(pixels)), chunk('IEND', Buffer.alloc(0)),
  ]);
}

function representativeGuide() {
  const modules = [
    'Orientation', 'Foundations', 'Approved identity assets', 'Usage and constraints',
    'Visual foundations', 'Typography', 'Imagery and illustration', 'Voice and messaging',
    'Application patterns', 'Resources and governance',
  ];
  return [
    '# Synthetic portable reference guide',
    '> State: DRAFT. Synthetic regression content, not approved downstream guidance.',
    'Scope: browser and print regression. Owner: synthetic fixture. Revision: fixture-294-v1.',
    'Use [local usage guidance](#usage-and-constraints) before applying any specimen.',
    '## Status and provenance',
    '| Source ID | Revision | Approval state | Supported module |',
    '|---|---|---|---|',
    '| synthetic-guidance | fixture-294-v1 | TEMPLATE | All fixture modules |',
    ...modules.flatMap((title, index) => [
      `## ${title}`,
      `Module ${index + 1}: ${title}. Essential rule: preserve scope, status and restrictions.`,
      `> Restriction ${index + 1}: specimens are examples only; no application approval is granted.`,
      '- Use: retain selectable explanations and local resources.',
      '- Avoid: hiding incomplete guidance or promoting unknown evidence.',
      '| Role | Example | Status |',
      '|---|---|---|',
      `| Module ${index + 1} role | Selectable textual alternative | TEMPLATE |`,
      ...Array.from({ length: 5 }, (_, paragraph) =>
        `Checkpoint ${index + 1}.${paragraph + 1}: ` +
        'This original synthetic instruction exercises complete-content pagination, responsive reading and governed handoff. ' +
        'Keep the rationale next to the rule and retain the use restriction when printing or sharing.'),
    ]),
    '## Long value',
    '`' + 'LongUnbrokenSemanticRoleName'.repeat(12) + '`',
    '## Review checks',
    '| Check | Result | Evidence |',
    '|---|---|---|',
    '| Accessibility specialist | UNKNOWN | Not performed by this regression suite |',
    '| Downstream approval | UNKNOWN | No downstream artifact reviewed |',
    'FINAL RESTRICTION: browser success is not WCAG certification or permission to publish.',
  ].join('\n');
}

async function mainContent(page) {
  return page.locator('main').evaluate((main, selector) => ({
    blocks: Array.from(main.querySelectorAll(selector))
      .map((element) => element.textContent?.replace(/\s+/g, ' ').trim()),
    headings: Array.from(main.querySelectorAll(selector))
      .flatMap((element, blockIndex) => /^H[1-6]$/.test(element.tagName) ?
        [{ blockIndex, id: element.id, level: Number(element.tagName.slice(1)) }] : []),
    tables: Array.from(main.querySelectorAll('table')).map((table) => {
      const blocks = Array.from(main.querySelectorAll(selector));
      const cells = Array.from(table.querySelectorAll('th,td'));
      return { headerIndices: Array.from(table.querySelectorAll('thead th')).map((cell) => blocks.indexOf(cell)),
        lastBlockIndex: blocks.indexOf(cells[cells.length - 1]) };
    }),
    unorderedListIndices: Array.from(main.querySelectorAll(selector))
      .flatMap((element, index) => element.tagName === 'LI' && element.parentElement.tagName === 'UL' ? [index] : []),
    images: Array.from(main.querySelectorAll('img')).map((image) => ({
      alt: image.alt, width: image.naturalWidth, height: image.naturalHeight,
    })),
  }), contentSelector);
}

async function expectedPrintContent(page, content, outputDirectory) {
  const sources = await page.locator('main img').evaluateAll((images) => images.map((image) => image.src));
  const pixels = sources.map((source, index) => {
    const imagePath = path.join(outputDirectory, `expected-image-${index}.png`);
    fs.writeFileSync(imagePath, source.startsWith('data:') ?
      Buffer.from(source.split(',')[1], 'base64') : fs.readFileSync(fileURLToPath(source)));
    return imagePath;
  });
  const identities = JSON.parse(execFileSync(python, [pdfInspector, '--image-identities', ...pixels],
    { encoding: 'utf8' }));
  return { ...content, images: content.images.map((image, index) => ({ ...image, ...identities[index] })) };
}

async function assertReflow(page, baseline) {
  expect(await mainContent(page)).toEqual(baseline);
  const measurement = await page.evaluate(() => {
    const root = document.documentElement;
    const elements = Array.from(document.querySelectorAll('main h1,main h2,main h3,main h4,main h5,main h6,main p,main li,main blockquote,main th,main td,main figcaption,main img'));
    return {
      viewport: innerWidth, scrollWidth: root.scrollWidth,
      clipped: elements.filter((element) => {
        const box = element.getBoundingClientRect();
        const style = getComputedStyle(element);
        return box.width <= 0 || box.height <= 0 || box.left < -1 || box.right > innerWidth + 1 ||
          style.visibility !== 'visible' || style.display === 'none' || style.opacity === '0' ||
          element.scrollHeight > element.clientHeight + 1 && style.overflowY === 'hidden' ||
          element.scrollWidth > element.clientWidth + 1 && style.overflowX === 'hidden';
      }).map((element) => element.tagName),
    };
  });
  expect(measurement.scrollWidth).toBeLessThanOrEqual(measurement.viewport + 1);
  expect(measurement.clipped).toEqual([]);
  return measurement;
}

test.describe('portable HTML measured Chromium evidence (#294)', () => {
  test.describe.configure({ retries: 0 });
  test.setTimeout(120000);

  for (const packaging of ['self-contained', 'local-bundle']) {
    test(`${packaging}: keyboard, offline, reflow and complete-content print`, async ({ browser }, testInfo) => {
      expect(testInfo.retry).toBe(0);
      const directory = testInfo.outputPath('guide');
      fs.mkdirSync(directory, { recursive: true });
      const guidePath = path.join(directory, 'guide.md');
      const htmlPath = path.join(directory, 'index.html');
      const manifestPath = path.join(directory, 'assets.json');
      fs.writeFileSync(guidePath, representativeGuide());
      fs.writeFileSync(path.join(directory, 'specimen.png'), specimenPng());
      fs.writeFileSync(manifestPath, JSON.stringify({
        assets: [{ id: 'synthetic-specimen', path: 'specimen.png', mediaType: 'image/png',
          alt: 'Two adjacent synthetic specimen panels; no guidance encoded in the image',
          permission: packaging === 'self-contained' ? 'embed' : 'copy' }],
      }));
      const cli = path.join(repoRoot, 'skills', 'style-guide-authoring', 'scripts', 'render-html-guide.ps1');
      const rendered = JSON.parse(execFileSync('pwsh', [
        '-NoProfile', '-File', cli, '-MarkdownPath', guidePath, '-OutputPath', htmlPath,
        '-Packaging', packaging, '-AssetManifestPath', manifestPath, '-RepoRoot', directory,
      ], { encoding: 'utf8', env: { ...process.env, TEMP: directory, TMP: directory, TMPDIR: directory } }));
      expect(rendered.State).toBe('DRAFT');
      expect(rendered.Checks.print).toBe('UNKNOWN');
      expect(rendered.Checks.navigation).toBe('UNKNOWN');

      const deliveredPaths = [htmlPath, ...rendered.Assets.map((asset) => asset.path).filter(Boolean)];
      if (packaging === 'local-bundle') {
        deliveredPaths.push(path.join(path.dirname(rendered.Assets[0].path), '.sga-html-assets.json'));
      }
      const report = {
        scope: 'source-regression', state: 'DRAFT', packaging, browser: browser.version(),
        platform: process.platform, executedAt: new Date().toISOString(),
        artifact: inventory(deliveredPaths), evidence: [],
        checks: Object.fromEntries(requiredChecks.map((name) => [name, { result: 'UNKNOWN' }])),
        limitations: [
          'Synthetic fixture only; no downstream guide approval or WCAG certification.',
          'Chromium only; no assistive technology or physical printer review.',
          '200% text enlargement measured using CSS font size, not native browser zoom.',
          'PDF geometry/text/image checks do not replace subjective visual or specialist review.',
        ],
      };
      const context = await browser.newContext({ javaScriptEnabled: false, offline: true,
        viewport: { width: 1280, height: 900 }, reducedMotion: 'reduce' });
      const page = await context.newPage();
      const network = [];
      const failedRequests = [];
      const errors = [];
      page.on('request', (request) => {
        if (/^(https?|wss?):/.test(request.url())) network.push(request.url());
      });
      page.on('requestfailed', (request) => failedRequests.push(request.url()));
      page.on('pageerror', (error) => errors.push(error.message));
      const run = (name, operation) => recordCheck(report, name, operation);
      const screenshot = async (name, target = undefined) => {
        const output = testInfo.outputPath(`${name}.png`);
        if (target) await page.locator(target).scrollIntoViewIfNeeded();
        else await page.evaluate(() => window.scrollTo(0, 0));
        await page.screenshot({ path: output });
        report.evidence.push(...inventory([output]));
        await testInfo.attach(name, { path: output, contentType: 'image/png' });
      };
      try {
        await run('offline', async () => {
          await page.goto(pathToFileURL(htmlPath).href);
          await expect(page.locator('script')).toHaveCount(0);
          await expect(page.locator('h1')).toHaveCount(1);
          await expect(page.locator('nav')).toHaveAttribute('aria-label', 'Guide sections');
          await expect(page.locator('html')).toHaveAttribute('lang', 'en');
          expect(await page.title()).toBe('Synthetic portable reference guide');
          const images = await page.locator('img').evaluateAll((items) =>
            items.map((image) => ({ decoded: image.complete && image.naturalWidth === 160,
              alternative: image.alt.length > 0 })));
          expect(images).toEqual([{ decoded: true, alternative: true }]);
          const fragmentTargets = await page.locator('a[href^="#"]').evaluateAll((links) =>
            links.map((link) => ({ href: link.getAttribute('href'),
              count: document.querySelectorAll(`[id="${link.getAttribute('href')?.slice(1)}"]`).length })));
          expect(fragmentTargets.every((target) => target.count === 1)).toBe(true);
          expect(network).toEqual([]);
          expect(failedRequests).toEqual([]);
          expect(errors).toEqual([]);
          return { javaScriptEnabled: false, offline: true, automaticRemoteRequests: [...network],
            failedRequests: [...failedRequests], images, fragmentTargets };
        });
        const baseline = await mainContent(page);
        expect(baseline.blocks).toHaveLength(188);
        await expect(page.locator('main table')).toHaveCount(12);
        await expect(page.locator('main h1,main h2')).toHaveCount(14);
        for (let module = 1; module <= 10; module++) {
          for (let checkpoint = 1; checkpoint <= 5; checkpoint++) {
            await expect(page.locator('main')).toContainText(`Checkpoint ${module}.${checkpoint}:`);
          }
        }
        await run('keyboard', async () => {
          await page.keyboard.press('Tab');
          const skip = page.locator('.sga-skip');
          await expect(skip).toBeFocused();
          const skipBox = await skip.boundingBox();
          expect(skipBox?.x).toBeGreaterThanOrEqual(0);
          await page.keyboard.press('Enter');
          await expect(page.locator('main')).toBeFocused();
          await page.keyboard.press('Tab');
          await expect(page.locator('main a').first()).toBeFocused();
          await page.keyboard.press('Shift+Tab');
          await page.goto(pathToFileURL(htmlPath).href);
          await page.keyboard.press('Tab');
          const links = page.locator('nav a');
          const targets = [];
          for (let index = 0; index < await links.count(); index++) {
            await page.keyboard.press('Tab');
            const link = links.nth(index);
            await expect(link).toBeFocused();
            const focus = await link.evaluate((element) => {
              const style = getComputedStyle(element);
              const rect = element.getBoundingClientRect();
              return { width: parseFloat(style.outlineWidth), style: style.outlineStyle,
                color: style.outlineColor, left: rect.left, right: rect.right,
                top: rect.top, bottom: rect.bottom, viewportHeight: innerHeight };
            });
            expect(focus.width).toBeGreaterThanOrEqual(2);
            expect(focus.style).not.toBe('none');
            expect(focus.color).not.toBe('rgba(0, 0, 0, 0)');
            expect(focus.left).toBeGreaterThanOrEqual(0);
            expect(focus.top).toBeGreaterThanOrEqual(0);
            expect(focus.bottom).toBeLessThanOrEqual(focus.viewportHeight);
            const href = await link.getAttribute('href');
            await page.keyboard.press('Enter');
            expect(new URL(page.url()).hash).toBe(href);
            const target = page.locator(href);
            const destination = await target.boundingBox();
            expect(destination?.y).toBeGreaterThanOrEqual(-1);
            expect(destination?.y).toBeLessThan(900);
            targets.push({ href, focus, destination });
            // Fragment activation moves sequential navigation to its destination.
            await page.goto(pathToFileURL(htmlPath).href);
            for (let tab = 0; tab <= index + 1; tab++) await page.keyboard.press('Tab');
          }
          await page.keyboard.press('Tab');
          await expect(page.locator('main a').first()).toBeFocused();
          await page.keyboard.press('Shift+Tab');
          await expect(links.last()).toBeFocused();
          return { skipFocus: 'main', navigationTargets: targets, escapedNavigation: true,
            reverseTab: true };
        });
        await screenshot('desktop');
        await run('reflow320', async () => {
          await page.setViewportSize({ width: 320, height: 640 });
          const result = await assertReflow(page, baseline);
          await screenshot('320-css-pixels');
          await screenshot('320-css-pixels-content', 'h1');
          return result;
        });
        await run('textZoom200', async () => {
          const initial = await page.locator('body').evaluate((element) => parseFloat(getComputedStyle(element).fontSize));
          await page.locator('body').evaluate((element) => element.style.setProperty('font-size', '32px', 'important'));
          const enlarged = await page.locator('body').evaluate((element) => parseFloat(getComputedStyle(element).fontSize));
          expect(enlarged / initial).toBe(2);
          const result = await assertReflow(page, baseline);
          await screenshot('320-css-pixels-text-200-percent');
          await screenshot('320-css-pixels-text-200-percent-content', 'h1');
          return { ...result, method: 'CSS text enlargement at 320 CSS pixels',
            initialFontPixels: initial, enlargedFontPixels: enlarged };
        });
        // Reload removes the text-enlargement override before printing.
        await page.goto('about:blank');
        await page.goto(pathToFileURL(htmlPath).href);
        await page.setViewportSize({ width: 1280, height: 900 });
        await page.emulateMedia({ media: 'print' });
        await expect(page.locator('nav')).toBeHidden();
        await expect(page.locator('.sga-skip')).toBeHidden();
        const printContent = await mainContent(page);
        expect(printContent).toEqual(baseline);
        const expectedPath = testInfo.outputPath('expected-print-content.json');
        fs.writeFileSync(expectedPath, JSON.stringify(await expectedPrintContent(page, printContent, testInfo.outputDir)));
        for (const format of ['A4', 'Letter']) {
          await run(`print${format}`, async () => {
            const pdfPath = testInfo.outputPath(`${format}.pdf`);
            await page.pdf({ path: pdfPath, format, printBackground: true });
            const previewPath = testInfo.outputPath(`${format}-preview.png`);
            const result = JSON.parse(execFileSync(python, [pdfInspector, pdfPath, expectedPath,
              format, previewPath], { encoding: 'utf8' }));
            expect(result.pages).toBeGreaterThanOrEqual(3);
            expect(result.missingBlocks).toEqual([]);
            expect(result.unexpectedLines).toEqual([]);
            expect(result.consumedLines).toBe(result.extractedLines);
            expect(result.outOfBounds).toEqual([]);
            expect(result.orphanedHeadings).toEqual([]);
            expect(result.printedImages).toBe(1);
            report.evidence.push(...inventory([pdfPath, previewPath]));
            await testInfo.attach(format, { path: pdfPath, contentType: 'application/pdf' });
            await testInfo.attach(`${format}-preview`, { path: previewPath, contentType: 'image/png' });
            return result;
          });
        }
        const initialOffline = report.checks.offline.measurements;
        await run('offline', async () => {
          expect(network).toEqual([]);
          expect(failedRequests).toEqual([]);
          expect(errors).toEqual([]);
          return { ...initialOffline, automaticRemoteRequests: [...network],
            failedRequests: [...failedRequests], verifiedAfterPrint: true };
        });
        report.evidence.push(...inventory([guidePath, manifestPath, expectedPath]));
        expect(assessEvidence(report, requiredChecks)).toBe('PASS');
        // Source regression and browser PASS can never attest to downstream READY.
        expect(report.state).toBe('DRAFT');
      } catch (error) {
        report.runFailure = String(error);
        throw error;
      } finally {
        const output = testInfo.outputPath('browser-print-evidence.json');
        await finalizeEvidence(report, requiredChecks, output, () => context.close(),
          (file) => testInfo.attach('browser-print-evidence', { path: file, contentType: 'application/json' }));
      }
    });
  }

  test('artifact-bound evidence fails closed for absent, failed or stale review', async ({}, testInfo) => {
    const artifact = testInfo.outputPath('artifact.html');
    const resource = testInfo.outputPath('bundle-resource.png');
    const evidence = testInfo.outputPath('measurement.json');
    fs.mkdirSync(path.dirname(artifact), { recursive: true });
    fs.writeFileSync(artifact, 'original guide bytes');
    fs.writeFileSync(resource, specimenPng());
    fs.writeFileSync(evidence, '{"measurement":1}');
    const report = { scope: 'source-regression', state: 'DRAFT',
      artifact: inventory([artifact, resource]), evidence: inventory([evidence]),
      checks: { browser: { result: 'PASS', measurements: { count: 1 } } } };
    expect(assessEvidence(report, ['browser'])).toBe('PASS');
    for (const result of ['FAIL', 'UNKNOWN', 'N/A', 'READY', undefined]) {
      expect(assessEvidence({ ...report, checks: { browser: { result } } }, ['browser'])).not.toBe('PASS');
    }
    expect(assessEvidence({ ...report, checks: {} }, ['browser'])).toBe('UNKNOWN');
    expect(assessEvidence({ ...report, checks: { browser: { result: 'PASS' } } }, ['browser'])).toBe('UNKNOWN');
    expect(assessEvidence({ ...report, artifact: [] }, ['browser'])).toBe('UNKNOWN');
    expect(assessEvidence({ ...report, evidence: [] }, ['browser'])).toBe('UNKNOWN');
    expect(assessEvidence({ ...report, scope: 'downstream-readiness' }, ['browser'])).toBe('UNKNOWN');
    expect(assessEvidence({ ...report, state: 'READY' }, ['browser'])).toBe('UNKNOWN');
    expect(assessEvidence({ ...report, runFailure: 'Failure outside a named check' }, ['browser'])).toBe('FAIL');
    fs.appendFileSync(resource, ' altered');
    expect(assessEvidence(report, ['browser'])).toBe('FAIL');
    report.artifact = inventory([artifact, resource]);
    fs.appendFileSync(artifact, ' altered');
    expect(assessEvidence(report, ['browser'])).toBe('FAIL');
    report.artifact = inventory([artifact, resource]);
    fs.appendFileSync(evidence, ' altered');
    expect(assessEvidence(report, ['browser'])).toBe('FAIL');
    fs.rmSync(evidence);
    expect(assessEvidence(report, ['browser'])).toBe('FAIL');
  });

  test('close and attachment failures persist FAIL even when attachment copies before throwing', async ({}, testInfo) => {
    fs.mkdirSync(testInfo.outputDir, { recursive: true });
    const artifact = testInfo.outputPath('artifact.html');
    fs.writeFileSync(artifact, 'Finalization fixture');
    for (const failing of ['close', 'attachment']) {
      const output = testInfo.outputPath(`${failing}-report.json`);
      const attached = testInfo.outputPath(`${failing}-attached.json`);
      const report = { scope: 'source-regression', state: 'DRAFT',
        artifact: inventory([artifact]), evidence: inventory([artifact]),
        checks: { browser: { result: 'PASS', measurements: { pages: 3 } } } };
      expect(assessEvidence(report, ['browser'])).toBe('PASS');
      await expect(finalizeEvidence(report, ['browser'], output,
        async () => { if (failing === 'close') throw new Error('Injected close failure'); },
        async (file) => {
          fs.copyFileSync(file, attached);
          if (failing === 'attachment') throw new Error('Injected attachment failure');
        })).rejects.toThrow(`Injected ${failing} failure`);
      const persisted = JSON.parse(fs.readFileSync(output, 'utf8'));
      expect(persisted.browserReview).toBe('FAIL');
      expect(persisted.runFailure).toContain(`Injected ${failing} failure`);
      expect(JSON.parse(fs.readFileSync(attached, 'utf8')).browserReview).not.toBe('PASS');
    }
  });

  test('simultaneous check, close and attachment failures preserve every cause', async ({}, testInfo) => {
    fs.mkdirSync(testInfo.outputDir, { recursive: true });
    const artifact = testInfo.outputPath('artifact.html');
    const output = testInfo.outputPath('combined-failures.json');
    fs.writeFileSync(artifact, 'Aggregate failure fixture');
    const report = { scope: 'source-regression', state: 'DRAFT',
      artifact: inventory([artifact]), evidence: inventory([artifact]),
      checks: { browser: { result: 'FAIL', rationale: 'Initial keyboard check failed' } },
      runFailure: 'Initial keyboard check failed' };
    let failure;
    try {
      await finalizeEvidence(report, ['browser'], output,
        async () => { throw new Error('Browser close failed'); },
        async () => { throw new Error('Report attachment failed'); });
    } catch (error) {
      failure = error;
    }
    expect(failure).toBeInstanceOf(AggregateError);
    expect(failure.errors).toHaveLength(3);
    const persisted = JSON.parse(fs.readFileSync(output, 'utf8'));
    expect(persisted.browserReview).toBe('FAIL');
    for (const cause of ['Initial keyboard check failed', 'Browser close failed', 'Report attachment failed']) {
      expect(persisted.runFailure).toContain(cause);
      expect(failure.message).toContain(cause);
    }
  });

  test('PDF inspector rejects omitted content and incorrect paper size', async ({ page }, testInfo) => {
    fs.mkdirSync(testInfo.outputDir, { recursive: true });
    await page.setContent('<h1>Diagnostic</h1><p>Incomplete PDF</p>');
    const pdf = testInfo.outputPath('incomplete.pdf');
    const expected = testInfo.outputPath('expected.json');
    fs.writeFileSync(expected, JSON.stringify({ blocks: ['Missing restriction'], headings: [], images: [] }));
    await page.pdf({ path: pdf, format: 'A4' });
    expect(() => execFileSync(python, [pdfInspector, pdf, expected, 'A4',
      testInfo.outputPath('A4.png')], { stdio: 'pipe' })).toThrow(/Missing essential text/);
    fs.writeFileSync(expected, JSON.stringify({ blocks: ['Diagnostic', 'Incomplete PDF'], headings: [], images: [] }));
    expect(() => execFileSync(python, [pdfInspector, pdf, expected, 'Letter',
      testInfo.outputPath('Letter.png')], { stdio: 'pipe' })).toThrow(/Wrong Letter page/);
    await page.setContent('<p style="position:absolute;left:10px">Out of bounds content</p>');
    await page.pdf({ path: pdf, format: 'A4' });
    fs.writeFileSync(expected, JSON.stringify({ blocks: ['Out of bounds content'], headings: [], images: [] }));
    expect(() => execFileSync(python, [pdfInspector, pdf, expected, 'A4',
      testInfo.outputPath('clipped.png')], { stdio: 'pipe' })).toThrow(/Clipped\/out-of-bounds content/);
  });

  test('late remote request marks offline evidence FAIL after earlier checks passed', async ({ browser }, testInfo) => {
    fs.mkdirSync(testInfo.outputDir, { recursive: true });
    const artifact = testInfo.outputPath('offline.html');
    fs.writeFileSync(artifact, '<main>Offline diagnostic</main>');
    const context = await browser.newContext({ offline: true });
    const page = await context.newPage();
    const network = [];
    page.on('request', (request) => {
      if (/^https?:/.test(request.url())) network.push(request.url());
    });
    await page.goto(pathToFileURL(artifact).href);
    const report = { scope: 'source-regression', state: 'DRAFT', artifact: inventory([artifact]),
      evidence: inventory([artifact]), checks: { offline: { result: 'PASS', measurements: { requests: 0 } },
        print: { result: 'PASS', measurements: { pages: 3 } } } };
    expect(assessEvidence(report, ['offline', 'print'])).toBe('PASS');
    const failed = page.waitForEvent('requestfailed');
    await page.evaluate(() => {
      const image = document.createElement('img');
      image.src = 'https://offline-diagnostic.invalid/late-resource.png';
      document.body.append(image);
    });
    await failed;
    await expect(recordCheck(report, 'offline', async () => {
      expect(network).toEqual([]);
      return { requests: network.length };
    })).rejects.toThrow();
    expect(report.checks.offline.result).toBe('FAIL');
    expect(assessEvidence(report, ['offline', 'print'])).toBe('FAIL');
    const output = testInfo.outputPath('late-network-evidence.json');
    fs.writeFileSync(output, JSON.stringify({ ...report, capturedRequests: network,
      browserReview: assessEvidence(report, ['offline', 'print']) }, null, 2));
    expect(JSON.parse(fs.readFileSync(output, 'utf8')).browserReview).toBe('FAIL');
    await context.close();
  });

  test('PDF boundaries detect missing repeated short blocks and orphaned actual h3', async ({ page }, testInfo) => {
    const directory = testInfo.outputPath('guide');
    fs.mkdirSync(directory, { recursive: true });
    const markdown = path.join(directory, 'guide.md');
    const html = path.join(directory, 'index.html');
    fs.writeFileSync(markdown, [
      '# Diagnostic guide', 'Purpose.', '## Status and provenance', 'Status details.',
      'Status', 'Status', '| Label | Status |', '|---|---|',
      '| First | Status |', '| Second | Status |',
      '### Small heading', 'Following content.',
    ].join('\n'));
    execFileSync('pwsh', ['-NoProfile', '-File', path.join(repoRoot, 'skills', 'style-guide-authoring',
      'scripts', 'render-html-guide.ps1'), '-MarkdownPath', markdown, '-OutputPath', html,
      '-RepoRoot', directory, '-Quiet'], {
      env: { ...process.env, TEMP: directory, TMP: directory, TMPDIR: directory },
    });
    await page.goto(pathToFileURL(html).href);
    await page.emulateMedia({ media: 'print' });
    const expected = testInfo.outputPath('expected.json');
    fs.writeFileSync(expected, JSON.stringify(await mainContent(page)));
    const pdf = testInfo.outputPath('diagnostic.pdf');
    const preview = testInfo.outputPath('diagnostic.png');
    const inspect = () => execFileSync(python, [pdfInspector, pdf, expected, 'A4', preview],
      { encoding: 'utf8', stdio: 'pipe' });
    await page.pdf({ path: pdf, format: 'A4', printBackground: true });
    expect(JSON.parse(inspect()).orphanedHeadings).toEqual([]);
    // The remaining Status and the longer heading/paragraph cannot mask deletion.
    await page.locator('main p').filter({ hasText: /^Status$/ }).first().evaluate((element) => element.remove());
    await page.pdf({ path: pdf, format: 'A4', printBackground: true });
    expect(inspect).toThrow(/Missing essential text/);
    await page.locator('main p').filter({ hasText: /^Status$/ }).evaluate((element) => element.remove());
    await page.pdf({ path: pdf, format: 'A4', printBackground: true });
    expect(inspect).toThrow(/Missing essential text/);
    await page.goto(pathToFileURL(html).href);
    await page.locator('td').filter({ hasText: /^Status$/ }).first().evaluate((element) => element.remove());
    await page.pdf({ path: pdf, format: 'A4', printBackground: true });
    expect(inspect).toThrow(/Missing essential text/);
    await page.goto(pathToFileURL(html).href);
    const headingPoints = await page.locator('h3').evaluate((element) =>
      parseFloat(getComputedStyle(element).fontSize) * 72 / 96);
    expect(headingPoints).toBeLessThan(14);
    await page.locator('h3').evaluate((element) => element.style.setProperty('break-after', 'auto', 'important'));
    await page.locator('main p').filter({ hasText: 'Following content.' }).evaluate((element) =>
      element.style.setProperty('break-before', 'page', 'important'));
    await page.pdf({ path: pdf, format: 'A4', printBackground: true });
    expect(inspect).toThrow(/Orphaned headings.*Small heading/);
  });

  test('reflow measurements reject hidden content and overflow, not just CSS flags', async ({ page }) => {
    await page.setViewportSize({ width: 320, height: 640 });
    await page.setContent('<main><h1>Fixture</h1><p>Essential instruction</p></main>');
    const baseline = await mainContent(page);
    await assertReflow(page, baseline);
    await page.locator('p').evaluate((element) => element.style.opacity = '0');
    await expect(assertReflow(page, baseline)).rejects.toThrow();
    await page.locator('p').evaluate((element) => {
      element.style.opacity = '1';
      element.style.height = '1px';
      element.style.overflow = 'hidden';
    });
    await expect(assertReflow(page, baseline)).rejects.toThrow();
    await page.locator('p').evaluate((element) => {
      element.removeAttribute('style');
      element.style.width = '640px';
    });
    await expect(assertReflow(page, baseline)).rejects.toThrow();
  });

  test('actual renderer h4-h6 omissions and orphans fail complete-content print', async ({ page }, testInfo) => {
    const directory = testInfo.outputPath('guide');
    fs.mkdirSync(directory, { recursive: true });
    const markdown = path.join(directory, 'guide.md');
    const html = path.join(directory, 'index.html');
    fs.writeFileSync(markdown, '# Guide\nPurpose.\n' + [2, 3, 4, 5, 6].map((level) =>
      `${'#'.repeat(level)} Level ${level}\nFollowing level ${level} content.`).join('\n'));
    execFileSync('pwsh', ['-NoProfile', '-File', path.join(repoRoot, 'skills', 'style-guide-authoring',
      'scripts', 'render-html-guide.ps1'), '-MarkdownPath', markdown, '-OutputPath', html,
      '-RepoRoot', directory, '-Quiet'], {
      env: { ...process.env, TEMP: directory, TMP: directory, TMPDIR: directory },
    });
    await page.goto(pathToFileURL(html).href);
    await page.emulateMedia({ media: 'print' });
    const content = await mainContent(page);
    expect(content.headings.map((heading) => heading.level)).toEqual([1, 2, 3, 4, 5, 6]);
    const expected = testInfo.outputPath('expected.json');
    fs.writeFileSync(expected, JSON.stringify(content));
    const pdf = testInfo.outputPath('lower-headings.pdf');
    const inspect = () => execFileSync(python, [pdfInspector, pdf, expected, 'A4',
      testInfo.outputPath('preview.png')], { encoding: 'utf8', stdio: 'pipe' });
    await page.pdf({ path: pdf, format: 'A4' });
    expect(JSON.parse(inspect()).missingBlocks).toEqual([]);
    for (const level of [4, 5, 6]) {
      await page.goto(pathToFileURL(html).href);
      await page.locator(`h${level}`).evaluate((element) => element.remove());
      await page.pdf({ path: pdf, format: 'A4' });
      expect(inspect).toThrow(new RegExp(`Missing essential text.*Level ${level}`));
      await page.goto(pathToFileURL(html).href);
      await page.locator(`h${level}`).evaluate((element) =>
        element.style.setProperty('break-after', 'auto', 'important'));
      await page.locator('p').filter({ hasText: `Following level ${level} content.` }).evaluate((element) =>
        element.style.setProperty('break-before', 'page', 'important'));
      await page.pdf({ path: pdf, format: 'A4' });
      expect(inspect).toThrow(new RegExp(`Orphaned headings.*Level ${level}`));
    }
  });

  test('printed distinct image identities consume a multiset and allow identical duplicates', async ({ page }, testInfo) => {
    const directory = testInfo.outputPath('guide');
    fs.mkdirSync(directory, { recursive: true });
    const markdown = path.join(directory, 'guide.md');
    const html = path.join(directory, 'index.html');
    const manifest = path.join(directory, 'assets.json');
    fs.writeFileSync(markdown, '# Image identity guide\nBoth specimens must print.');
    fs.writeFileSync(path.join(directory, 'a.png'), specimenPng());
    fs.writeFileSync(path.join(directory, 'b.png'), specimenPng(true));
    fs.writeFileSync(manifest, JSON.stringify({ assets: ['a', 'b'].map((id) => ({
      id, path: `${id}.png`, mediaType: 'image/png', alt: `Distinct specimen ${id}`, permission: 'embed',
    })) }));
    execFileSync('pwsh', ['-NoProfile', '-File', path.join(repoRoot, 'skills', 'style-guide-authoring',
      'scripts', 'render-html-guide.ps1'), '-MarkdownPath', markdown, '-OutputPath', html,
      '-AssetManifestPath', manifest, '-RepoRoot', directory, '-Quiet'], {
      env: { ...process.env, TEMP: directory, TMP: directory, TMPDIR: directory },
    });
    await page.goto(pathToFileURL(html).href);
    await page.emulateMedia({ media: 'print' });
    const expected = testInfo.outputPath('expected.json');
    const content = await expectedPrintContent(page, await mainContent(page), testInfo.outputDir);
    expect(content.images[0].width).toBe(content.images[1].width);
    expect(content.images[0].pixelSha256).not.toBe(content.images[1].pixelSha256);
    fs.writeFileSync(expected, JSON.stringify(content));
    const pdf = testInfo.outputPath('images.pdf');
    const inspect = () => execFileSync(python, [pdfInspector, pdf, expected, 'A4',
      testInfo.outputPath('preview.png')], { encoding: 'utf8', stdio: 'pipe' });
    await page.pdf({ path: pdf, format: 'A4' });
    expect(JSON.parse(inspect()).printedImages).toBe(2);
    const firstSource = await page.locator('img').first().getAttribute('src');
    await page.locator('img').nth(1).evaluate((element, source) => element.src = source, firstSource);
    await expect(page.locator('img').nth(1)).toHaveJSProperty('complete', true);
    await page.pdf({ path: pdf, format: 'A4' });
    expect(inspect).toThrow(/Unexpected or duplicated printed image identity/);
    fs.writeFileSync(expected, JSON.stringify({ ...content,
      images: [content.images[0], content.images[0]] }));
    expect(JSON.parse(inspect()).printedImages).toBe(2);
    await page.locator('img').nth(1).evaluate((element) => element.remove());
    await page.pdf({ path: pdf, format: 'A4' });
    expect(inspect).toThrow(/Printed image count differs/);
  });

  test('renderer keeps h4-h6 with following content at real A4 and Letter page boundaries', async ({ page }, testInfo) => {
    const directory = testInfo.outputPath('guide');
    fs.mkdirSync(directory, { recursive: true });
    const markdown = path.join(directory, 'guide.md');
    const html = path.join(directory, 'index.html');
    fs.writeFileSync(markdown, '# Boundary guide\nPurpose.\n## Level 2\nContext.\n### Level 3\nContext.\n' +
      '### Boundary spacer\nSpacer.\n#### Level 4\nFollowing level 4.\n##### Level 5\nFollowing level 5.\n' +
      '###### Level 6\nFollowing level 6.');
    execFileSync('pwsh', ['-NoProfile', '-File', path.join(repoRoot, 'skills', 'style-guide-authoring',
      'scripts', 'render-html-guide.ps1'), '-MarkdownPath', markdown, '-OutputPath', html,
      '-RepoRoot', directory, '-Quiet'], {
      env: { ...process.env, TEMP: directory, TMP: directory, TMPDIR: directory },
    });
    for (const format of ['A4', 'Letter']) {
      for (const level of [4, 5, 6]) {
        await page.goto(pathToFileURL(html).href);
        await page.emulateMedia({ media: 'print' });
        // Move a preceding content block's height so the heading fits on page
        // one but its following text does not. The renderer must move both.
        await page.locator(`h${level}`).evaluate((heading, paperHeight) => {
          const previous = heading.previousElementSibling;
          const style = getComputedStyle(heading);
          const printableHeight = paperHeight * 96 / 72 - 24 * 96 / 25.4;
          const target = printableHeight - 16 - heading.getBoundingClientRect().height -
            parseFloat(style.marginBottom) - parseFloat(getComputedStyle(document.body).lineHeight) / 2;
          previous.style.height = `${previous.getBoundingClientRect().height +
            target - heading.getBoundingClientRect().top}px`;
        }, format === 'A4' ? 841.89 : 792);
        const expected = testInfo.outputPath(`${format}-h${level}.json`);
        fs.writeFileSync(expected, JSON.stringify(await mainContent(page)));
        const pdf = testInfo.outputPath(`${format}-h${level}.pdf`);
        const inspect = () => execFileSync(python, [pdfInspector, pdf, expected, format,
          testInfo.outputPath(`${format}-h${level}.png`)], { encoding: 'utf8', stdio: 'pipe' });
        const initialHeight = await page.locator(`h${level}`).evaluate((heading) =>
          parseFloat(heading.previousElementSibling.style.height));
        // Calibrate within one line around the boundary; PDF pagination rounds
        // differently from the continuous print-media DOM on each paper size.
        await page.locator(`h${level}`).evaluate((heading) =>
          heading.style.setProperty('break-after', 'auto', 'important'));
        let exercised = false;
        for (let offset = -40; offset <= 40; offset += 4) {
          await page.locator(`h${level}`).evaluate((heading, height) =>
            heading.previousElementSibling.style.height = `${height}px`, initialHeight + offset);
          await page.pdf({ path: pdf, format });
          try {
            inspect();
          } catch (error) {
            if (new RegExp(`Orphaned headings.*Level ${level}`).test(String(error))) {
              exercised = true;
              break;
            }
            throw error;
          }
        }
        expect(exercised).toBe(true);
        // Restore the actual renderer rule at the exact calibrated boundary.
        await page.locator(`h${level}`).evaluate((heading) => heading.style.removeProperty('break-after'));
        await page.pdf({ path: pdf, format });
        expect(JSON.parse(inspect()).orphanedHeadings).toEqual([]);
      }
    }
  });

  test('PDF conserves every line including expected repeats and wrapped table cells', async ({ page }, testInfo) => {
    const directory = testInfo.outputPath('guide');
    fs.mkdirSync(directory, { recursive: true });
    const markdown = path.join(directory, 'guide.md');
    const html = path.join(directory, 'index.html');
    fs.writeFileSync(markdown, '# Conservation guide\nRepeated body instruction.\nRepeated body instruction.\n' +
      '## Table guidance\nAll content must survive.\n| Role | Instruction |\n|---|---|\n' +
      '| Repeated role | ' + 'This table cell must wrap across multiple lines while preserving all words. '.repeat(8) +
      '|\n| Repeated role | Repeated body instruction. |');
    execFileSync('pwsh', ['-NoProfile', '-File', path.join(repoRoot, 'skills', 'style-guide-authoring',
      'scripts', 'render-html-guide.ps1'), '-MarkdownPath', markdown, '-OutputPath', html,
      '-RepoRoot', directory, '-Quiet'], {
      env: { ...process.env, TEMP: directory, TMP: directory, TMPDIR: directory },
    });
    await page.goto(pathToFileURL(html).href);
    await page.emulateMedia({ media: 'print' });
    const expected = testInfo.outputPath('expected.json');
    fs.writeFileSync(expected, JSON.stringify(await mainContent(page)));
    const pdf = testInfo.outputPath('conservation.pdf');
    const inspect = () => execFileSync(python, [pdfInspector, pdf, expected, 'A4',
      testInfo.outputPath('preview.png')], { encoding: 'utf8', stdio: 'pipe' });
    await page.pdf({ path: pdf, format: 'A4' });
    const positive = JSON.parse(inspect());
    expect(positive.consumedLines).toBe(positive.extractedLines);
    expect(positive.extractedLines).toBeGreaterThan(positive.expectedBlocks);
    for (const mutation of ['duplicate', 'injected', 'duplicate-cell', 'duplicate-header', 'trailing']) {
      await page.goto(pathToFileURL(html).href);
      await page.locator('main').evaluate((main, kind) => {
        if (kind === 'duplicate-header') {
          const header = main.querySelector('thead');
          header.after(header.cloneNode(true));
          return;
        }
        if (kind === 'duplicate-cell') {
          const cell = main.querySelector('td');
          cell.after(cell.cloneNode(true));
          return;
        }
        const paragraph = document.createElement('p');
        paragraph.textContent = kind === 'duplicate' ? 'Repeated body instruction.' : 'Unrecognized injected instruction.';
        if (kind === 'trailing') main.append(paragraph);
        else main.insertBefore(paragraph, main.querySelector('h2'));
      }, mutation);
      await page.pdf({ path: pdf, format: 'A4' });
      expect(inspect).toThrow(mutation === 'trailing' ? /Unexpected unconsumed printed text/ :
        /Missing essential text|Unexpected unconsumed printed text/);
    }
    await page.goto(pathToFileURL(html).href);
    await page.locator('tbody tr').first().evaluate((row) =>
      row.style.setProperty('break-after', 'page', 'important'));
    await page.pdf({ path: pdf, format: 'A4' });
    const repeated = JSON.parse(inspect());
    expect(repeated.repeatedTableHeaders).toHaveLength(1);
    expect(repeated.consumedLines).toBe(repeated.extractedLines);
  });

  test('long unbroken navigation heading reflows at 320px and 200% text', async ({ page }, testInfo) => {
    const directory = testInfo.outputPath('guide');
    fs.mkdirSync(directory, { recursive: true });
    const markdown = path.join(directory, 'guide.md');
    const html = path.join(directory, 'index.html');
    fs.writeFileSync(markdown, '# Long heading guide\nPurpose.\n## ' +
      'UnbrokenNavigationHeading'.repeat(16) + '\nSelectable guidance.');
    execFileSync('pwsh', ['-NoProfile', '-File', path.join(repoRoot, 'skills', 'style-guide-authoring',
      'scripts', 'render-html-guide.ps1'), '-MarkdownPath', markdown, '-OutputPath', html,
      '-RepoRoot', directory, '-Quiet'], {
      env: { ...process.env, TEMP: directory, TMP: directory, TMPDIR: directory },
    });
    await page.setViewportSize({ width: 320, height: 640 });
    await page.goto(pathToFileURL(html).href);
    const baseline = await mainContent(page);
    await assertReflow(page, baseline);
    await page.locator('body').evaluate((element) => element.style.fontSize = '32px');
    await assertReflow(page, baseline);
    const nav = await page.locator('nav a').last().boundingBox();
    expect(nav.x).toBeGreaterThanOrEqual(0);
    expect(nav.x + nav.width).toBeLessThanOrEqual(321);
    // Without the production wrapping rule the same supported heading overflows.
    await page.locator('nav').evaluate((element) => element.style.overflowWrap = 'normal');
    await expect(assertReflow(page, baseline)).rejects.toThrow();
  });

  test('PDF preserves literal leading bullets and strips only semantic list markers', async ({ page }, testInfo) => {
    const directory = testInfo.outputPath('guide');
    fs.mkdirSync(directory, { recursive: true });
    const markdown = path.join(directory, 'guide.md');
    const html = path.join(directory, 'index.html');
    fs.writeFileSync(markdown, '# • Literal heading\n• Literal paragraph\n- Semantic list instruction\n' +
      '- • Literal bullet inside list\n## Table\nContext.\n| • Literal header | Value |\n|---|---|\n' +
      '| • Literal cell | Unchanged value |');
    execFileSync('pwsh', ['-NoProfile', '-File', path.join(repoRoot, 'skills', 'style-guide-authoring',
      'scripts', 'render-html-guide.ps1'), '-MarkdownPath', markdown, '-OutputPath', html,
      '-RepoRoot', directory, '-Quiet'], {
      env: { ...process.env, TEMP: directory, TMP: directory, TMPDIR: directory },
    });
    await page.goto(pathToFileURL(html).href);
    await page.emulateMedia({ media: 'print' });
    const expected = testInfo.outputPath('expected.json');
    fs.writeFileSync(expected, JSON.stringify(await mainContent(page)));
    const pdf = testInfo.outputPath('bullets.pdf');
    const inspect = () => execFileSync(python, [pdfInspector, pdf, expected, 'A4',
      testInfo.outputPath('preview.png')], { encoding: 'utf8', stdio: 'pipe' });
    await page.pdf({ path: pdf, format: 'A4' });
    expect(JSON.parse(inspect()).missingBlocks).toEqual([]);
    for (const kind of ['removed', 'injected']) {
      await page.goto(pathToFileURL(html).href);
      await page.locator('main p').filter({ hasText: 'Literal paragraph' }).evaluate((element, mutation) => {
        element.textContent = mutation === 'removed' ? 'Literal paragraph' : '•• Literal paragraph';
      }, kind);
      await page.pdf({ path: pdf, format: 'A4' });
      expect(inspect).toThrow(/Missing essential text/);
    }
  });
});
