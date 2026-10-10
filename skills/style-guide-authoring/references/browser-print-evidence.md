# Portable HTML browser and print evidence

This contract travels with the copied skill. Use the existing
`scripts/render-html-guide.ps1`, not a separate renderer. The source repository's
Chromium suite is regression evidence for synthetic content only; it does not
approve your guide. No Node/Python dependency or source checkout is required for
ordinary portable generation. Browser/PDF inspection tools are review tooling.

## Source regression tooling versus consumer prerequisites

The source-only suite pins its PDF inspector dependency in
`tests/visual-regression/requirements.txt` (PyMuPDF `1.27.2.2`, the verified
version). Source CI runs in a Linux Playwright container and installs it with
`python3 -m pip install -r tests/visual-regression/requirements.txt`.
Local Windows validation uses
`python -m pip install -r tests\visual-regression\requirements.txt`.
Run the existing `npm run test:visual` after restoring locked Node dependencies
and installing Playwright Chromium; the configured test directory discovers the
guide tests automatically. PowerShell 7 remains necessary for the actual portable
renderer invoked by these tests.

The requirements file and Python/Node test helpers are source regression assets,
not part of the copied skill or prerequisites for generating consumer guides.
Consumers performing readiness review need suitable real-browser and PDF
inspection tooling, but need not install this source suite or PyMuPDF specifically.
Missing review tooling leaves the applicable check UNKNOWN, never PASS.

Retain `test-results/**` together, including generated HTML/resources, evidence
JSON, screenshots, A4/Letter PDFs and all-page previews; optionally retain
`playwright-report/**` when using the configured HTML reporter. Evidence binds the
actual delivered artifacts, not just PDF creation success or CSS declarations.

## Review the actual delivered artifact

1. Record timestamp, operator, platform, browser/version, packaging/profile,
   viewport, zoom method and actual guide revision. Inventory SHA-256 of final
   HTML plus every delivered bundle resource (including ownership manifest).
   Hash final PDF/screenshot evidence and replay expectations such as
   `expected-print-content.json` too: those digests bind the actual assertions to
   the reviewed artifact. Expectation/baseline hashes never substitute for final
   HTML, bundle or resource hashes. Structural references (for example a supplied
   reference deck, not generated test expectations) must never be fingerprinted.
2. Open the final HTML from `file:` in real Chromium, disable JavaScript, capture
   requests and test offline. Require zero automatic remote requests, decoded
   local images, readable essential text and resolving local fragment links.
   Clicking deliberately external resource links is outside the offline claim.
3. At desktop width, Tab to the visible skip link and activate it; check focus
   reaches main and subsequent Tab reaches main links. Exercise every navigation
   link with Tab/Enter, confirm correct fragments, visible focus and visible
   destination. Shift+Tab must work and Tab must escape navigation without a trap.
4. At 320 CSS pixels, then at 200% text enlargement, measure document overflow
   (at most 1 CSS pixel rounding allowance). Compare all essential text, table
   cells and images with the original artifact; detect clipping/hidden content.
   If using desktop 200% browser zoom, record its resulting CSS viewport as well.
   CSS transforms or device scale factors alone are not text-zoom evidence.
5. Print the entire guide to A4 and Letter with print backgrounds. Inspect actual
   PDFs: correct paper dimensions, multiple pages for long guides, every essential
   text block/table cell/status/restriction present, text within page bounds, no
   clipped specimens or missing images. Inspect page previews for legibility,
   heading/orphan handling and overlap. PDF creation or print CSS alone is not PASS.

## Fail-closed handoff

Record each required check as PASS, FAIL, UNKNOWN or justified N/A with scope,
measurements, rationale and evidence paths/digests. Missing tooling or unexecuted
inspection is UNKNOWN. Changed HTML/assets or missing/changed evidence invalidates
prior PASS; rerun on the final bytes. Keep evidence outside guide-owned outputs so
checks do not mutate guides, timestamps, ownership records or URL metadata.

Confirmed mandatory failure blocks delivery; missing/stale required evidence
leaves DRAFT. Renderer success, CURRENT freshness and source-suite PASS cannot
promote READY. READY additionally needs complete approved inputs and applicable
owner/specialist review, including actual contrast pairs and alternatives.

Limitations must name the tested browser/platform and scope. Chromium PDF output
does not validate all browsers, physical printers, assistive technologies,
subjective image meaning or all WCAG criteria. Text-enlargement testing is not
proof of native zoom on every platform. Do not claim WCAG certification, legal
clearance, publication authorization or automatic downstream approval.
