# Changelog

All notable changes to basecoat-sheen are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and this project adheres
to [Semantic Versioning](https://semver.org/spec/v2.0.0.html). Renaming a published
asset is a breaking change (major bump) per [`.lexicon.md`](.lexicon.md) §2.

## [Unreleased]

## [0.9.0] — 2026-08-18

### Added
- **`scripts/audit-design-md.ps1`** — PowerShell org-wide DESIGN.md audit. Scans
  a GitHub org (or explicit repo list) for sheen consumers, reports DESIGN.md
  presence, token tier coverage, and sheen version. Emits a markdown audit report
  to stdout or `-Out <file>`. Supports `-GenerateMissing` to dispatch the
  `generate-design-md-callable.yml` workflow for any repo missing DESIGN.md.
- **`.github/workflows/generate-design-md-callable.yml`** — reusable callable
  workflow (`workflow_call` + `workflow_dispatch`) that generates `DESIGN.md` from
  a consumer's `sheen/tokens/` and opens a PR. Mirrors the callable pattern of
  `check-sheen-version-callable.yml`. Consumer repos can also trigger it directly
  via `gh workflow run`.
- **`sheen-integrate.prompt.md` Phase 4b** — DESIGN.md generation step in the
  integration workflow; offers `generate_design_md: true` config for persistent
  auto-generation.
- **`sheen-upgrade.prompt.md` Phase 4b** — DESIGN.md regeneration step in the
  upgrade workflow; surfaces the generate option for repos that don't have it yet.

### Why this matters
With v0.8.1 (DESIGN.md export) the tooling existed but was not surfaced in
consumer-facing workflows. This release closes the loop: operators can now audit
an entire org for DESIGN.md status in one command, auto-generate for missing repos,
and have DESIGN.md generation baked into every integrate and upgrade flow.



### Added
- **`check-sheen-version-callable.yml`** — reusable GitHub Actions workflow
  (`workflow_call`) that consumer repos reference to auto-sync sheen assets and
  open a PR when a new version is available. Mirrors the `check-basecoat-version-callable.yml`
  model: checks out the consumer repo, runs `sync.sh`, detects changes, commits
  to a branch, and opens a governed PR. Supports `source_repo`, `source_ref`,
  `auto_merge`, custom `pr_branch_prefix`, and `fetch_token` / `update_token` secrets.
- **`templates/sheen-sync.yml`** — consumer-side workflow template (weekly schedule
  + manual dispatch) that calls the callable. Distributed to consumer repos on
  first sync — no extra setup required.
- **`sync.ps1` / `sync.sh`** — now deploys `templates/sheen-sync.yml` to
  `.github/workflows/sheen-sync.yml` in the consumer repo on first sync (if the
  file doesn't already exist). Provides the same auto-update experience as basecoat
  from the very first `pwsh sync.ps1` run.
- **`.sheen.yml.example`** — documented the auto-update workflow with guidance on
  how to disable it if needed.

### Why this matters
The gap between basecoat and sheen onboarding experience was architectural:
basecoat uses a **callable reusable workflow** that consumer repos schedule;
sheen was **pull-only** (manual `sync.ps1`). This release closes that gap.

## [0.8.2] — 2026-08-18

### Fixed
- **Onboarding bootstrap paradox** — consumers could not invoke `/sheen-onboard`
  because the skill only exists after sync, but no guidance existed on how to
  get `sync.ps1` before running it. Root cause: documentation assumed `sync.ps1`
  was already in the consumer repo with no explanation of how to obtain it.

### Added
- **`bootstrap.ps1`** + **`bootstrap.sh`** — single-file bootstrap scripts that
  consumers run once from inside their repo. Downloads `sync.ps1`/`sync.sh`,
  creates a starter `.sheen.yml`, and runs the initial sync in one step.
  One-liners:
  - Windows: `pwsh -c "iex (iwr https://raw.githubusercontent.com/ivegamsft/sheen/main/bootstrap.ps1).Content"`
  - macOS/Linux: `bash <(curl -fsSL https://raw.githubusercontent.com/ivegamsft/sheen/main/bootstrap.sh)`
- **`README.md`** — new "Getting started in 60 seconds" section with bootstrap
  one-liners, context reset instructions, and a callout warning about the
  `/sheen-onboard` paradox.
- **`consumer-lifecycle.md` Phase 1** — leads with the bootstrap one-liner;
  "Manual path" section documents `sync.ps1`/`sync.sh` download commands for
  advanced users.
- **`sheen-integrate.prompt.md` Phase 0** — new "Bootstrap sync scripts" phase
  before discover/generate; includes OS-specific one-liners and skip conditions.
- **`skills/sheen-onboard/SKILL.md`** — added bootstrap error recovery block
  (shows the one-liner to run when SKILL.md is not found) and Phase 0 in the
  lifecycle table.

## [0.8.1] — 2026-08-18

### Added
- **`scripts/build-design-md.ps1`** + **`scripts/build-design-md.sh`** — export
  `DESIGN.md` from DTCG tokens in [Google Stitch format](https://stitch.withgoogle.com/docs/design-md).
  Resolves all token aliases and emits a flat, AI-readable snapshot of resolved
  colours, typography, spacing, and corner radii. Supports `--theme` override,
  `--out` custom path, and `--check` validation mode.
- **`generate_design_md: true`** sync option — auto-generates `DESIGN.md` at the
  repo root on every `sync` run.
- **`design_md_theme: <name>`** sync option — which resolved theme to export
  (defaults to `light`).
- **`design-md-export`** vocab intent — triggers via keywords: `design-md`,
  `design.md`, `export-tokens`, `stitch`, `ai-design-context`.
- **`docs/guides/consumer-lifecycle.md` Phase 2** — added Step 6 "Generate
  DESIGN.md", manual usage section, and updated gate to require `DESIGN.md` at
  repo root before Phase 3.
- **`.sheen.yml.example`** — documented `generate_design_md` and `design_md_theme`
  options with inline comments.

## [0.8.0] — 2026-08-18

### Added
- **`PRODUCT.md`** — product specification for basecoat-sheen following the
  [product.md spec](https://product.md/): Register, Users, Problem, Product Purpose,
  Brand Personality/Tone, Anti-references, Design Principles (5), Accessibility &
  Inclusion (WCAG 2.2 AA/AAA), Offer (MIT/OSS), Boundaries, Stack. Machine islands
  for pricing and stack in spec-qualified fenced blocks. MDXLD frontmatter
  (`$type: Product`). Published to docs as `docs/product.md` via snippets include.
- **`vendor/basecoat/prompts/design.prompt.md`** — `design:` intent prompt. Anchors
  every design request to `PRODUCT.md` (design principles, brand personality, a11y
  floor, boundaries), routes to the correct sheen pillar agent, and produces
  PRODUCT.md-grounded output. Also handles `design: create PRODUCT.md for this product`
  discovery and generation workflow.
- **`vendor/basecoat/prompts/debate.prompt.md`** — `debate:` intent prompt. Structured
  design debate: generates 2–4 options, scores each against PRODUCT.md design principles
  using a weighted matrix, applies WCAG hard gate, declares a winner, and produces an
  ADR-style decision record ready to commit to `docs/decisions/`.

## [0.7.3] — 2026-08-18

### Fixed
- **Consumer token materialization path** (#92): `sync.ps1` / `sync.sh` now invoke
  `scripts/build-tokens.ps1` with explicit `-TokensDir sheen/tokens` and
  `-OutDir dist/tokens`. `build-tokens.ps1` also auto-detects consumer layout via
  `.sheen/manifest.json` or `sheen/tokens` when those parameters are omitted, so
  provisioned builders no longer default to a missing root `tokens/` directory.
- **Diagnostics scope in mixed BaseCoat consumers** (#93): `diagnose-sheen.ps1` /
  `diagnose-sheen.sh` structure and collision checks now prefer
  `.sheen/manifest.json` (then `.sheen.yml` allow-lists) so unrelated BaseCoat
  skills/agents under `.github/` are not validated against Sheen rules. Regression
  coverage added in `scripts/test-diagnose-sheen.ps1`.

## [0.7.2] — 2026-08-18

### Fixed
- `scripts/diagnose-sheen.ps1` and `scripts/diagnose-sheen.sh`: repaired logging
  validation — log-level parsing now handles edge cases that caused false negatives
  in the diagnose output. Regression coverage added in `scripts/test-diagnose-sheen.ps1`.
  (closes #91)

## [0.7.1] — 2026-08-18

### Added
- **Integration steps** — Phase 1 of `docs/guides/consumer-lifecycle.md` now includes a
  full step-by-step manual path with concrete `.sheen.yml` examples, allow-list warnings
  guidance, and a **Reset Copilot context** step (Step 5) explaining how to reload skills
  after sync in Copilot CLI, VS Code, and JetBrains.
- **Phase 6 — Upgrade** added to `consumer-lifecycle.md` with quick-start prompt, manual
  steps, and context reset guidance.
- **`vendor/basecoat/prompts/sheen-integrate.prompt.md`** — agent-invocable prompt that
  drives the full first-time integration workflow (discover → generate `.sheen.yml` → sync
  → validate → commit → reset context → summary report).
- **`vendor/basecoat/prompts/sheen-upgrade.prompt.md`** — agent-invocable prompt that
  drives a safe upgrade workflow (discover → changelog → sync → allow-list reconciliation
  → validate → commit → reset context → summary report).
- **`docs/guides/upgrading-sheen.md`** — new "Resetting Copilot context after upgrade"
  section with per-client instructions (CLI, VS Code, JetBrains) and a verification table.

### Fixed
- Troubleshooting table in `consumer-lifecycle.md` updated to include context-reload
  symptoms and the correct `sheen/tokens/` path (was `tokens/`).
- Duplicate `ADR-001` link in "See also" removed.

## [0.7.0] — 2026-08-19

### Added
- **Upgrade process** — `scripts/upgrade-sheen.ps1` and `scripts/upgrade-sheen.sh`: six-phase
  consumer upgrade workflow (prereqs → detect → changelog preview → sync → diagnose → PR).
  Mirrors the basecoat `bootstrap-basecoat.ps1` pattern. (`docs/guides/upgrading-sheen.md`,
  `docs/examples/sheen-upgrade.workflow.yml`).

### Fixed
- **Sync multi-source path resolution** (#80, #81): `sync.ps1` and `sync.sh` now check multiple
  source locations per asset type (`.github/skills`, `.github/agents`, `.github/prompts`, etc.)
  so all skills and prompts reach downstream consumers — not only `sheen-onboard`.
- **Sync allow-list normalization** (#80): `Normalize-Name` / `normalize_name` strips asset-type
  suffixes (`.agent`, `.instructions`, `.prompt`, `.tokens`) from both source filenames and
  allow-list values, enabling consistent matching regardless of suffix style.
- **Sync empty allow-list semantics** (#82): `sync: agents: []` now means "sync none" and
  removes previously-synced entries on re-sync, rather than syncing all agents.
- **Sync collision protection** (#83): existing consumer-authored files are preserved when their
  path matches an upstream asset; a warning is emitted and the upstream copy is skipped.
- **Sync nested exclude support** (#84): `sync.exclude` patterns are now evaluated per asset
  type using the source-relative path, matching documented `.sheen.yml` behavior.
- **Sync themes allow-list filtering** (#85): `sync.tokens.themes` allow-list correctly prunes
  theme files after directory copy and normalizes `.tokens` suffixes during comparison.
- **Rollback consumer safety** (#80): `rollback.ps1` and `rollback.sh` now remove only
  manifest-recorded individual files, preserving consumer-authored additions.
- **`materialize_tokens` fresh consumer** (#86): when `materialize_tokens: true` is set and
  `scripts/build-tokens.ps1` is absent in the consumer repo, `sync.ps1` / `sync.sh` now
  provisions the script from the upstream clone before invoking it.
- **Agent allow-list unmatched warning** (#88): `sync.ps1` and `sync.sh` now emit a warning
  for each allow-list entry that did not match any source file, making typos immediately visible.
- **Lifecycle scripts consumer path auto-detection** (#87): `validate-tokens.ps1`,
  `warn-rules.ps1`, `contrast-check.ps1`, and `build-metadata.ps1` now auto-detect consumer
  repos (presence of `.sheen/manifest.json`) and resolve canonical consumer asset paths
  (`.github/skills`, `sheen/tokens`, etc.) without requiring manual path flags.
- **Skill descriptions** — stripped boilerplate `"Use when this skill is the right fit..."`
  prefix from all 45 consumer-facing `skills/*/SKILL.md` files; each now opens with a specific
  trigger sentence followed by `USE FOR:` / `DO NOT USE FOR:`.

## [0.6.4] — 2026-08-18

### Fixed
- Publish sanitizer target expansion:
  - Includes plain internal owner tokens in scan targets, not only owner/repo path forms.
  - Prevents leakage from release metadata fields such as `version.json` notes.

## [0.6.3] — 2026-08-18

### Fixed
- Publish sanitization hotfix: scrubs plain internal owner tokens (`IBuySpy-Shared`)
  in addition to owner/repo paths, preventing leakage from release notes/changelog text.

## [0.6.2] — 2026-08-18

### Fixed
- Hardened public publish sanitization in `publish-to-production.yml`:
  - Strips `.github/skills/**` and `vendor/**` from the production payload.
  - Expands internal-owner scrub + safety gate to block leaked `IBuySpy-Shared` and
    `ibuyspy-shared.github.io` references outside `LICENSE`.
- Prevents internal owner/repo details from leaking into the public mirror content.

## [0.6.1] — 2026-08-18

### Fixed
- Docs rendering parity with basecoat on GitHub Pages:
  - Material icon shortcodes now render correctly (`:material-*:`) via `pymdownx.emoji`.
  - Navigation/tabs/theme styling restored with MkDocs Material parity configuration.
  - Added docs static assets used by the theme (`docs/stylesheets/extra.css`, `docs/javascripts/external-links.js`).
- Production docs deployment reliability:
  - `docs.yml` bootstraps GitHub Pages using the repo `GITHUB_TOKEN` on first deployment.
  - `publish-to-production.yml` dispatches production docs workflow after publish instead of trying PAT-based Pages enablement.

## [0.6.0] — 2026-08-18

### Added
- **Wave 1/2 — Semantic tokens + token pipeline** (#43, #44, #49):
  - 4 new semantic token files: `tokens/semantic/space.tokens.json`,
    `elevation.tokens.json`, `motion.tokens.json`, `border.tokens.json` (80 keys).
  - All 3 theme files (light/dark/high-contrast) updated to cover all 80 semantic keys;
    high-contrast elevation uses flat/transparent shadows for accessibility.
  - `scripts/build-tokens.ps1` — DTCG→CSS/JS/ESM/TypeScript pipeline with cycle detection.
  - `materialize_tokens` opt-in added to `sync.ps1` and `sync.sh`; documented in `.sheen.yml.example`.
- **Wave 2 — Agent quality** (#47, #51):
  - All 6 agent descriptions updated with `USE FOR` / `DO NOT USE FOR` triggers.
  - `composes.instructions` wired on all 6 agents.
- **Wave 2 — Consumer lifecycle guide** (`docs/guides/consumer-lifecycle.md`):
  - 5-phase Integrate→Onboard→Inventory→Audit→Use playbook with copy-paste prompts,
    agent flows, output shapes, gate conditions, and a troubleshooting table.
- **Wave 3 — Spec compliance tools** (#40, #41, #45, #48, #50, #52, #56):
  - `discriminator` field added to all 46 intents; vocab schema bumped to `sheen-vocab/v2`.
  - `scripts/lint-router.ps1` + `router-contract` CI job (6 validation checks).
  - `scripts/contrast-check.ps1` — standalone WCAG contrast checker (21 pairs, all-themes mode).
  - `scripts/warn-rules.ps1` — 5 warn-level governance rules (W01 token-budget,
    W02 description-overlap, W03 skill-body-size, W04 aria-keyboard, W05 eval-coverage).
  - `templates/vpat-statement.md` — WCAG 2.2 AA conformance statement (47 criteria, AT test matrix).
  - `.markdownlint.json` + markdownlint CI step (warn-only).
  - `sync.sh` `materialize_tokens` block for parity with `sync.ps1`.
- **Wave 4 — 11 comprehensive governance skills** (#55, #59–#68), growing skills from 46→57:
  - `design-to-code` — scaffold React/Vue/Web Components from spec + tokens.
  - `design-drift-detection` — spec-vs-implementation parity audit.
  - `sheen-onboard` — agent-driven 5-phase consumer lifecycle orchestration.
  - `design-system-versioning` — semver classification, migration guides, deprecation timelines.
  - `performance-aware-design` — Core Web Vitals (LCP/CLS/INP) impact assessment for design decisions.
  - `data-visualisation` — chart type selection, data density rules, accessible colour encoding.
  - `ai-output-governance` — review AI-generated copy/imagery/UI for bias, hallucination, brand safety.
  - `ethical-design` — dark pattern detection (10 patterns), consent UI, GDPR/ISO 29184 review.
  - `design-adoption-telemetry` — token and component usage analytics in production codebases.
  - `mobile-native-design` — iOS HIG and Android Material You design mapping with parity reports.
  - `design-sprint` — full GV-style sprint facilitation (HMW, storyboard, prototype spec, test script).
  - Each skill ships with `SKILL.md` (workflow, sample prompts, output schema, agent pairing)
    and `eval.yaml` (4 positive + 2 negative routing scenarios ≥ 7.0 threshold).
- **Publishing flow** — `publish-to-production.yml` + `token-preflight.yml`:
  - Mirrors tagged releases to the public production repo (`ivegamsft/sheen`).
  - Strips internal CI tooling; sanitizes `IBuySpy-Shared/basecoat-sheen` → `ivegamsft/sheen`.
  - `release.yml` updated to gate on `PRODUCTION_REPO_TOKEN` preflight before creating release.

### Changed
- `sheen-metadata.json` skill count: 46 → 57; `sheen.vocab.yaml` schema: v1 → v2.
- Docs: `reference/skills-catalog.md` and `guides/prompts/index.md` updated with Wave 4 skills.



### Added
- Consumer onboarding quick-start guide with three adoption modes (lean,
  token-only, full), adoption-mode profiles, and an onboarding FAQ (#19).
- Real-world consumption patterns with config recipes, diagrams, and FAQs:
  solo-design, cross-functional, cross-org, token-only, and migration (#20).
- Token build, theme application, and CI integration docs (CSS, Figma tokens,
  Storybook, pre-commit, changelog automation) plus an example consumer under
  `examples/consumer-tokens/` (#21).
- Cross-repo sync validation & diagnostics tooling: `scripts/diagnose-sheen.ps1`
  and `scripts/diagnose-sheen.sh` (token-resolution checks across themes,
  basecoat/sheen namespace-collision detection, human report + JSON manifest)
  with `docs/guides/diagnostics.md` (#23).
- Automated eval routing gate: `scripts/audit-evals.ps1`,
  `scripts/test-eval-routing.ps1`, and a `eval-routing` CI job (#24).
- Publish/release tooling aligned with basecoat: `.github/workflows/release.yml`
  (tag-triggered), `.github/workflows/version-check.yml` (version.json ↔ CHANGELOG
  gate), and `scripts/generate-release-notes.sh` (#32).

### Changed
- Docs site information architecture reordered to the consumption flow
  (discover → onboard → integrate → operate) with search, SEO/social meta,
  and quick-reference cards (#22).
- Hardened the 46 skill and 6 agent `eval.yaml` files; bottom-quartile routing
  evals rewritten to meet the specificity threshold (#24).

### Fixed
- `version.json` had a duplicate `"version"` key (0.3.0/0.4.0); collapsed to a
  single value and now gated by the version-consistency check (#32).
- Remediated 10 Dependabot alerts (9 high, 1 moderate) in skill lockfiles:
  `js-yaml`, `minimatch`, `nanoid`, and `brace-expansion` (#34).

## [0.4.0] — 2026-08-14

### Added
- `tokens/semantic/type.tokens.json` — 10 DTCG composite typography role tokens
  (`display`, `heading-1`, `heading-2`, `heading-3`, `body`, `body-sm`, `label`,
  `caption`, `code`, `code-sm`). Each is a `$type: "typography"` composite
  referencing core `type.*` primitives via aliases. Resolves template references
  to `typography.body`, `typography.heading-1`, etc.
- `LICENSE` (MIT) — closes SPEC §13 D5.

### Changed
- `scripts/validate-tokens.ps1` — extend `$AllowedTypes` to include `'typography'`,
  `'elevation'`, and `'material'` composite types per DTCG §9 / spec 01 §2.
- `tokens/themes/{light,dark,high-contrast}.tokens.json` — add `type.*` entries
  for theme-layer completeness; values are identical across themes (typography
  does not vary by colour scheme).
- `SPEC.md §13` — close all remaining open/proposed decisions: D2 (full breadth),
  D3 (standalone sibling), D4 (DTCG JSON), D5 (MIT), D6 (mkdocs-material),
  D7 (WCAG 2.2 AA + ISO 9241/25010 + OWASP UX).
- `checks.json` — version bump 0.1.0 → 0.2.0.

## [0.3.0] — 2026-08-14

### Added
- Instruction layer (bands 10–90): ten always-on ambient instruction files that
  load design values, accessibility, token naming, component states, web usability,
  brand voice, information architecture, taxonomy, content/i18n, and standards
  conformance into every Copilot session.
  - `instructions/sheen-10-core-design-principles.instructions.md`
  - `instructions/sheen-10-core-accessibility.instructions.md`
  - `instructions/sheen-20-tokens-naming.instructions.md`
  - `instructions/sheen-30-components-states.instructions.md`
  - `instructions/sheen-40-web-usability.instructions.md`
  - `instructions/sheen-50-brand-voice.instructions.md`
  - `instructions/sheen-60-ia-navigation.instructions.md`
  - `instructions/sheen-70-taxonomy-ontology.instructions.md`
  - `instructions/sheen-80-content-multilingual.instructions.md`
  - `instructions/sheen-90-standards-conformance.instructions.md`
- Shared cross-skill templates for four categories: `style-guide`,
  `component-spec`, `brand-guidelines`, and `design-review`. Each includes a
  `README.md` (usage guidance) and a populated starter template.

## [0.2.0] — 2026-08-14

### Added
- `docs/reference/incident-learnings.md` to capture build and automation
  incident learnings with RCA-oriented evidence and follow-up guardrails.
- `docs/reference/model-capabilities.json` and
  `docs/reference/model-capabilities.md` to provide model capability governance
  and ownership/update process for skill and agent audits.

### Changed
- Upgraded `skills/design-debate/SKILL.md` from a generic stub to a concrete,
  auditable decision workflow (weighted criteria, option matrix, risk and
  reversibility checks, and ADR-ready output contract).
- Refined `skills/design-debate/eval.yaml` scenarios to improve routing
  disambiguation against neighboring review and token-edit requests.
- Replaced scaffold-level placeholder bodies in 37 repo skills with
  category-specific, BaseCoat-spec workflows, guardrails, and output contracts
  while preserving each skill's scope and delegate pairings.
- Normalized remaining skill description prefaces to start with `Use when ...`
  and upgraded 37 generic routing eval files to domain-realistic prompts for
  stronger activation/disambiguation coverage.

## [0.1.0] — Phase 0 · Scaffold

### Added
- Repository structure: pillar directories for `tokens/{core,semantic,themes}`,
  `skills/`, `agents/`, `instructions/`, `prompts/`, `templates/`, `docs/`,
  `references/`, and `scripts/`.
- Governance: `README.md`, `CONTRIBUTING.md`, `.lexicon.md`, and
  `docs/design-context.md`.
- Consumer config: `.sheen.yml.example`, `checks.json` (validation manifest),
  and generated `sheen-metadata.json` (empty asset inventory).
- Consumption tooling: `sync.ps1` / `sync.sh` and `rollback.ps1` / `rollback.sh`
  (idempotent, manifest-based).
- Version tracking: `version.json` and this changelog.

### Notes
- No skills, agents, instructions, or tokens are published in this release; the
  pillars are scaffolded and ready to be populated in later phases (SPEC §11).
- The upstream `basecoat` framework remains vendored read-only under
  `vendor/basecoat/` and is not modified by sheen.

[Unreleased]: https://github.com/IBuySpy-Shared/basecoat-sheen/compare/v0.4.0...HEAD
[0.4.0]: https://github.com/IBuySpy-Shared/basecoat-sheen/releases/tag/v0.4.0
[0.3.0]: https://github.com/IBuySpy-Shared/basecoat-sheen/releases/tag/v0.3.0
[0.2.0]: https://github.com/IBuySpy-Shared/basecoat-sheen/releases/tag/v0.2.0
[0.1.0]: https://github.com/IBuySpy-Shared/basecoat-sheen/releases/tag/v0.1.0
