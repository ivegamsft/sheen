# Style Guide Authoring

Use `style-guide-authoring` when a downstream repo needs a governed guide from
approved guidance. The skill keeps Markdown as the default deliverable and adds
portable HTML only when the request explicitly asks for it.

## What is available

| Request | Result |
|---|---|
| Generate or template without a format | Markdown guide or neutral template |
| Explicit offline HTML | Self-contained `.html` file, default 5 MiB budget |
| Explicit local bundle | Entry HTML plus relative `assets/` files, default 25 MiB budget |
| Refresh | Current guides are no-op; stale or unknown evidence is reported without writes |
| Check freshness | Read-only CURRENT, STALE, UNKNOWN or BLOCKED report |
| Audit | Findings and decision log only; no artifact writes |

HTML output is a delivery profile, not publication. It does not update
`metadata.style_guide_url`, upload files, change application styles or approve
identity decisions. Those actions require separate authorization.

## Consumer delivery

Sync the complete skill folder, not individual source files:

```yaml
source: https://github.com/ivegamsft/sheen.git
ref: main
skills:
  - style-guide-authoring
agents:
  - design-reviewer
templates:
  - style-guide
```

After sync, a consumer repo should have:

```text
.github/skills/style-guide-authoring/SKILL.md
.github/skills/style-guide-authoring/eval.yaml
.github/skills/style-guide-authoring/references/
.github/skills/style-guide-authoring/scripts/
.github/skills/style-guide-authoring/templates/guide-outline.md
.github/agents/design-reviewer.agent.md
sheen/templates/style-guide/
```

The copied skill-local scripts are sufficient for portable HTML and freshness
checks. Consumers do not need source-only top-level generators such as
`scripts/build-design-md.ps1` to use the copied skill folder.

## Evidence

The delivered contract is covered by synthetic fixtures only. Source regression
and consumer readiness evidence are deliberately separate:

| Area | Evidence |
|---|---|
| Input mapping, freshness, no-op refresh and stale/unknown handling | `scripts/test-guide-inputs.ps1` |
| HTML profiles, byte budgets, safe assets, ownership and browser acceptance | `scripts/test-guide-html.ps1`, `tests/visual-regression/style-guide-html.spec.js` |
| Routing scenarios, complete payload metadata and synced consumer execution | `scripts/test-guide-consumer-delivery.ps1` |

These checks distinguish deterministic local evidence from unresolved specialist
review. A generated guide remains `DRAFT` unless required review evidence exists;
failed or unexecuted checks cannot produce `READY`.

### Reproducing real browser and print regression (#294)

From the source checkout, with its existing locked Node dependencies restored,
Chromium installed for Playwright, PowerShell 7 and Python with PyMuPDF available:

```powershell
npm run test:visual -- style-guide-html.spec.js --reporter=list
```

The PDF inspector uses `python` on Windows and `python3` elsewhere. Missing
Chromium/Python/PyMuPDF fails the run; do not omit PDF inspection to obtain PASS.
No dependency manifests are added for consumer guide generation. Source test
helpers are review tooling, not another renderer or part of the synced skill.

The suite generates original representative guides with all ten module roles,
provenance/status tables, restrictions, long unbroken text and a local raster
specimen, using the actual skill-local helper in both packaging modes. It checks
real Tab/Shift+Tab/Enter, skip-link focus, every fragment destination and visible
focus, offline loading with JavaScript disabled and zero remote requests,
320 CSS-pixel overflow and 200% text enlargement. It inspects actual A4/Letter
PDF text using ordered, boundary-preserving normalized extraction-line ranges
with multiplicity, decoded RGB pixel identity multisets, page bounds and
DOM-identified h1–h6 orphan checks.
Every extracted line must be consumed exactly once from the current cursor;
extra, reordered or trailing text fails. One leading Chromium unordered-list
bullet is normalized only for recorded DOM unordered-list items when needed to
match their text; literal leading bullets in paragraphs/headings/tables and list
content remain intact. Chromium's repeated semantic
table header is consumed only at a new-page boundary inside that exact DOM table,
matching its recorded complete header sequence; these repetitions are enumerated
in `repeatedTableHeaders`. No generic text-skipping whitelist is used.
Negative tests reject hidden/clipped content, wrong paper, incomplete PDF content
and failed/missing/changed artifact evidence, omitted/orphaned lower headings,
duplicate-A/missing-B specimens, late remote requests and finalization failures.

`test-results/` retains generated guides, screenshots, PDFs, all-page raster
previews and `browser-print-evidence.json` per packaging mode. Reports inventory
actual delivered HTML/resources and evidence by SHA-256 and record Chromium
version, platform, time, measurements and limitations. They say
`scope: source-regression`, `state: DRAFT`; `browserReview: PASS` is not READY.
The canonical per-test `browser-print-evidence.json` is finalized only after
browser close and report attachment succeed. Attachment snapshots conservatively
remain UNKNOWN while attachment is pending (or FAIL after an earlier failure);
they never preannounce PASS. A close/attachment failure is persisted as
`runFailure` and canonical FAIL before rethrowing. Original check/run failures and
subsequent close/attachment failures remain together in the report and thrown
AggregateError. Use the canonical report in
the uploaded `test-results/**` evidence package for the final result.
Archive these files together before another Playwright run replaces its output.
Absolute paths in local reports must be rebased when moving an evidence package;
verify every digest again, never substitute an unrelated guide with the same name.

Recorded source run on 2026-10-10: Windows, Chromium `151.0.7922.34`, fifteen browser
tests passed; both packaging modes printed nine A4 and nine Letter pages with
188 expected text blocks, one decoded/printed specimen, zero remote requests and
320px document width both normally and with 200% text enlargement. Desktop,
narrow/text-enlarged screenshots and all-page print contact sheets were visually
inspected for this synthetic fixture only. HTML SHA-256 for that run:

- Self-contained: `8056f96dcfd8df8cb19e87e7a8840fa3789699a695d3b3dad8b35aff4df6762a`
- Local-bundle entry: `0523994561d8e78fcd991e0e4a6da36bfdc8c06ce470c9f1f4a3f649c5e68b1c`

The retained per-run reports also bind bundle resources, PDF and screenshot
digests; entry HTML alone is not a complete bundle attestation. Packaging
(eight scenarios) and input/freshness (twelve scenarios) regressions passed.
Whole-folder consumer delivery passed all six scenarios after shared metadata
integration, including the browser/print evidence reference in both required
payload and copied-consumer manifest checks after the h1–h6 print rule and
platform-specific installation guidance updates. The fifteen-browser-test rerun
also verified persisted FAIL for injected close, attachment-copy-then-fail and
simultaneous check/close/attachment paths. Actual-renderer h4–h6 page-boundary
fixtures pass on A4 and Letter with the production keep-with-content rule;
disabling that rule at the same calibrated positions produces orphan failures.
Expected repeated paragraphs/table cells and wrapped table content pass full-line
conservation; duplicated body text/table cells, injected middle text and trailing
unrecognized text fail. Six consumer scenarios and metadata freshness also passed.
Linux CI run `38077160776` retained PDFs revealed a legitimate repeated
`Review checks` table header on page nine, not omitted approval content.
Both exact failing A4 PDFs replayed locally with their original expected content
plus table boundaries derived from the delivered HTML: all 294 extracted lines
were consumed, including the three repeated header cells; all 188 expected blocks,
geometry, heading and image checks passed. Subsequently, corrected-head
[Linux CI run 38078582828](https://github.com/ivegamsft/sheen/actions/runs/38078582828)
completed successfully at `0d7fcef6ebc38efcc37bf67292018808e78a0c5d`, with all
fifteen source Chromium tests including actual print checks passing. This is
synthetic source regression evidence, not downstream approval; consumer
readiness remains artifact-specific and DRAFT without required review.
A forced page-break table positive and
same-page duplicated-header negative supplement the thirteen local browser tests.
The latest fifteen-test run additionally exercises a long unbroken navigation
heading at 320 CSS pixels and 200% text enlargement (disabling wrapping fails),
and literal-bullet PDF positives with removed/injected-bullet negatives.

### Portable downstream handoff

After sync, read
`.github/skills/style-guide-authoring/references/browser-print-evidence.md`.
Repeat its browser/PDF checks on the **final consumer artifact**, preserving a
separate report with actual guide and asset digests, check results, rationale,
operator and evidence. A source-suite PASS cannot be attached as approval of a
different guide; regeneration or asset edits invalidate prior evidence.
Keep checks read-only and evidence outside managed guide outputs.

The synthetic suite does not establish all-browser behavior, native browser zoom
on every platform, assistive-technology compatibility, actual contrast/alternative
quality, physical-printer fidelity or WCAG certification. Visual inspection and
applicable specialist/owner review remain necessary. No automatic downstream
approval, publication, metadata update or release is inferred.
