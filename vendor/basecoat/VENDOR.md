# Vendored: basecoat

This directory is a **vendored copy** of the upstream basecoat governance repo. It
provides the engineering-SDLC foundation that basecoat-sheen (the design/UX
"finish coat") builds on top of.

## Provenance

| Field | Value |
|---|---|
| Source | https://github.com/IBuySpy-Shared/basecoat |
| Commit | `daf83646e67abd6a4e71852917b4acd9fa4075c0` |
| Commit date | 2026-08-10 |
| Vendored on | 2026-08-13 |
| License | See [`LICENSE`](LICENSE) |

## What is included

The customization assets and the tooling that operates them:

- `skills/` — basecoat skill library (566 files)
- `agents/` — basecoat agents (371 files)
- `instructions/` — layered `basecoat-*` instructions (128 files)
- `prompts/`, `templates/`, `scripts/`
- Root governance/config: `checks.json`, `.basecoat.yml.example`,
  `basecoat-metadata.json`, `version.json`, `sync.*`, `rollback.*`,
  `.lexicon.md`, `.gitattributes`, `.markdownlint.json`, `README.md`,
  `CONTRIBUTING.md`, `LICENSE`.

## What is intentionally excluded

Heavy, generated, or repo-specific content not needed for the asset library:
`.git/`, `analysis/`, `docs/` (mkdocs site), `portal/`, `dashboard/`, `reports/`,
`.github/` (basecoat's own CI), `tests/`, `mcp/`, `plugins/`, `sdks/`, `infra/`,
`extensions/`.

## Update policy

- Treat this tree as **read-only**. Do not hand-edit vendored files; changes belong
  upstream in basecoat.
- Refresh by re-cloning at a new pinned commit and replacing this directory, then
  bumping the Provenance table above and noting it in the repo `CHANGELOG.md`.
- sheen assets live at the repo root (`../../skills`, `../../agents`, etc.) and MUST
  NOT be placed under `vendor/`.

## Naming & precedence

- basecoat assets keep the `basecoat-*` prefix; sheen assets use `sheen-*`. The two
  namespaces never collide, so both can be synced into a consumer together.
- Where a design concern overlaps an engineering one, the sheen asset governs the
  design surface and delegates deeper engineering/security work to the vendored
  basecoat asset (see root `SPEC.md` §3 and `specs/08`).
