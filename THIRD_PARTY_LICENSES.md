# Third-Party Attribution

This repository is MIT-licensed (see [`LICENSE`](LICENSE)). This file tracks
attribution for design guidance, editorial rules, and lint logic that was
**adapted or ported** from third-party sources — even where no source code
was copied verbatim — so that provenance stays auditable per repository
license policy.

## cathrynlavery/diagram-design

| Field | Value |
|---|---|
| Source | https://github.com/cathrynlavery/diagram-design |
| License | MIT |
| Copyright | © 2025 Cathryn Lavery |
| Used under | Epic [#110](https://github.com/IBuySpy-Shared/basecoat-sheen/issues/110) — Diagram Design Integration |

### What was adapted

No files from the upstream repository are vendored or copied verbatim.
The following basecoat-sheen assets **independently re-implement** concepts,
rule sets, and conventions that originate from cathrynlavery/diagram-design,
adapted to this repo's DTCG token system and PowerShell tooling conventions:

| basecoat-sheen asset | Adapted from upstream | Issue |
|---|---|---|
| `scripts/build-diagram-skins.ps1` | Diagram semantic-role naming convention (`paper`, `ink`, `muted`, `rule`, `accent`, `series.N`, ...) | #116 |
| `scripts/lint-diagram-skins.ps1` | `lint-skin` and `verify-skin-polarity` checks (originals in Python; re-implemented in PowerShell) | #118 |
| `scripts/lint-diagram-geometry.ps1` | Connector/label geometry rules (slant angle, shared attachment points, path overlap, label masking, clipping, transit-behind-node ordering) | #118 |
| `scripts/audit-diagram-slop.ps1` | Editorial "anti-slop" guidance (density budget, no-shadow/max-radius, focal-accent budget, no neon/stray colour, no blanket mono-font) | #115 |
| `skills/design-audit/SKILL.md` ("Diagram Anti-Slop Rules" section) | Same editorial guidance as above, expressed as an audit rule table | #115 |

Each adapted script or doc section carries an in-file header comment noting
the upstream origin (see the "Ported/adapted from cathrynlavery/diagram-design"
comments at the top of the scripts listed above) so provenance stays visible
without needing to consult this file.

### What was NOT adapted (independently authored)

The following are original to basecoat-sheen and are **not** derived from
the upstream project, even though they serve the same epic:

- `tokens/semantic/color.tokens.json` and theme overrides (`color.data.*`) —
  this repo's own DTCG token values (#112).
- `skills/data-visualisation/*-template.md` — written against this repo's
  existing `templates/component-spec/` and `templates/style-guide/`
  conventions (#119).
- `docs/decisions/adr-003` through `adr-006` — original architecture
  decision records documenting *this* repo's choices, informed by (but not
  copied from) the upstream project's defaults (#114).

### Upstream license text

```
MIT License

Copyright (c) 2025 Cathryn Lavery

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

Both this repository and the upstream project are MIT-licensed, so there is
no license conflict: MIT permits adaptation and re-implementation under the
same terms, and this file plus the in-file header comments satisfy MIT's
attribution expectation for the design concepts and rule sets carried over.

## tabler/tabler-icons (vendored subset)

| Field | Value |
|---|---|
| Source | https://github.com/tabler/tabler-icons |
| License | MIT |
| Copyright | © 2020-2026 Paweł Kuna |
| Used under | Epic [#110](https://github.com/IBuySpy-Shared/basecoat-sheen/issues/110), issue [#111](https://github.com/IBuySpy-Shared/basecoat-sheen/issues/111) — icon vendoring for the documentation-diagram renderer |

Unlike the diagram-design entry above, this **is** a literal vendored copy:
19 `outline`-variant SVG icon files, pinned at commit
`5a0fe38e97784d94279ce4eb1bf85f9a91bf027e`, live under
[`vendor/tabler-icons/icons/outline/`](vendor/tabler-icons/icons/outline/),
alongside the preserved upstream [`LICENSE`](vendor/tabler-icons/LICENSE).
Full provenance, the curated icon list, and inclusion/exclusion rationale are
tracked in [`vendor/tabler-icons/VENDOR.md`](vendor/tabler-icons/VENDOR.md).

`scripts/build-icons.ps1` normalizes the vendored SVGs into `dist/icons/`
(git-ignored, rebuilt on every CI run) and regenerates
[`docs/foundations/icon-gallery.md`](docs/foundations/icon-gallery.md) — no
hand-maintained copy of icon markup exists outside `vendor/tabler-icons/`.

Both this repository and tabler-icons are MIT-licensed; the upstream
copyright and permission notice are preserved verbatim in
`vendor/tabler-icons/LICENSE`, satisfying MIT's attribution requirement for
the vendored files.

## Policy

- Any future work that adapts guidance, rules, or logic from a third-party
  project (regardless of its license) must:
  1. Add an entry to this file naming the source, its license, and exactly
     what was adapted vs. independently authored.
  2. Add a one-line header comment in the adapting file(s) pointing back to
     the source.
  3. If literal source code (not just concepts/rules) is copied, vendor it
     under `vendor/<name>/` following the convention in
     `vendor/basecoat/VENDOR.md` (full upstream `LICENSE` preserved
     alongside the vendored tree) instead of inlining it here.
- Cross-check new entries against the root [`LICENSE`](LICENSE) (MIT) to
  confirm no conflicting terms before merging.
