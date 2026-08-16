# Changelog

All notable changes to basecoat-sheen are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and this project adheres
to [Semantic Versioning](https://semver.org/spec/v2.0.0.html). Renaming a published
asset is a breaking change (major bump) per [`.lexicon.md`](.lexicon.md) §2.

## [Unreleased]

## [0.5.0] — 2026-08-16

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
