# Changelog

All notable changes to basecoat-sheen are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and this project adheres
to [Semantic Versioning](https://semver.org/spec/v2.0.0.html). Renaming a published
asset is a breaking change (major bump) per [`.lexicon.md`](.lexicon.md) §2.

## [Unreleased]

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
