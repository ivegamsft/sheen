# Vendored: basecoat

This directory is a **vendored copy** of the upstream basecoat governance repo. It
provides the engineering-SDLC foundation that basecoat-sheen (the design/UX
"finish coat") builds on top of.

## Provenance

| Field | Value |
|---|---|
| Source | <https://github.com/IBuySpy-Shared/basecoat> |
| Ref | `v4.6.4` |
| Commit | `01d96489247d56f444d1fbed446f93bd65b6c7c3` |
| Commit date | 2026-10-08 |
| Vendored on | 2026-10-10 |
| License | See [`LICENSE`](LICENSE) |

## What is included

The customization assets and the tooling that operates them:

- `skills/` — basecoat skill library
- `agents/` — basecoat agents
- `instructions/` — layered `basecoat-*` instructions
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

`scripts/validate-pr-intake-preflight.cjs` is also excluded: it is an upstream
repository-specific PR control-plane entrypoint that requires an evaluator in
the excluded `.github/` runtime. Sheen does not invoke it. Keep both outside this
asset-library snapshot rather than shipping a broken entrypoint or importing
the upstream control plane. Included upstream files remain byte-identical.

## Update policy

- Treat this tree as **read-only**. Do not hand-edit vendored files; changes belong
  upstream in basecoat.
- Downstream security mitigations must be tracked upstream and update vendored
  manifest hashes. The reusable-workflow secret diagnostics redaction
  (IBuySpy-Shared/basecoat#3420) is closed upstream and included in this snapshot.
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
