# Changelog

All notable changes to basecoat-sheen are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and this project adheres
to [Semantic Versioning](https://semver.org/spec/v2.0.0.html). Renaming a published
asset is a breaking change (major bump) per [`.lexicon.md`](.lexicon.md) §2.

## [Unreleased]

### Added
- `docs/reference/incident-learnings.md` to capture build and automation
  incident learnings with RCA-oriented evidence and follow-up guardrails.

### Changed
- Upgraded `skills/design-debate/SKILL.md` from a generic stub to a concrete,
  auditable decision workflow (weighted criteria, option matrix, risk and
  reversibility checks, and ADR-ready output contract).
- Refined `skills/design-debate/eval.yaml` scenarios to improve routing
  disambiguation against neighboring review and token-edit requests.

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

[Unreleased]: https://github.com/IBuySpy-Shared/basecoat-sheen/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/IBuySpy-Shared/basecoat-sheen/releases/tag/v0.1.0
