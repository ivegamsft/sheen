# Spec 06 — Consumption & Sync

> Normative spec for `.sheen.yml`, `sync.*`, and `rollback.*`. Implements root
> SPEC §10. Basecoat-compatible so a consumer can adopt both frameworks the same
> way.

## 1. `.sheen.yml` (consumer config)

Placed at a consumer repo root. All keys optional; omit to accept defaults.
A `.sheen.yml.example` in this repo documents every key.

```yaml
# -- Sync configuration --
source: https://github.com/YOUR-ORG/basecoat-sheen.git   # upstream (or private fork)
ref: main                                                 # branch or release tag (pin for stability)

# Allow-lists — omit a key to sync ALL of that asset type.
skills:        [design-audit, design-tokens, accessibility-audit]
agents:        [design-reviewer]
instructions:  [sheen-10-core-design-principles, sheen-40-web-usability]
themes:        [light, dark, high-contrast]               # token themes to pull

sync:
  script: scripts/sheen/sync-sheen.ps1   # override if not root sync.*
  exclude:
    - archive/
```

Rules:
- `source`/`ref` select the upstream and version. Consumers SHOULD pin `ref` to a
  release tag in production.
- Each allow-list, when present, is an explicit include set; when absent, all
  assets of that type sync.
- `themes` selects which token themes are materialized in the consumer.

## 2. `sync.*` (`sync.ps1` / `sync.sh`)

- Clone/fetch `source` at `ref`, resolve allow-lists, and copy selected assets
  into the consumer's customization directory.
- MUST be idempotent: re-running with the same config yields the same tree.
- MUST record what it wrote (a manifest) so `rollback.*` can revert precisely.
- Runs token build (spec 01 §4) if the consumer opts into materialized tokens.
- PowerShell and shell entry points MUST stay behavior-equivalent.

## 3. `rollback.*` (`rollback.ps1` / `rollback.sh`)

- Reverts the last sync (or to a named prior manifest/ref).
- MUST not touch consumer-authored files outside the recorded manifest.

## 4. Versioning contract

- This repo publishes releases via `version.json` + `CHANGELOG.md` (semver).
- Breaking changes (renamed/removed published skill, agent, semantic token, or
  theme) require a major bump and a CHANGELOG migration note.
- Consumers pinned to a tag are insulated until they move `ref`.

## 5. Relationship to basecoat

`.sheen.yml` intentionally parallels `.basecoat.yml`; a repo may carry both. The
two sync mechanisms are independent but share conventions, so tooling and operator
knowledge transfer. sheen adds the `themes` key and token materialization, which
basecoat has no equivalent for.

## 6. Vendored basecoat

basecoat is vendored at `vendor/basecoat/` (root SPEC §3.1). Two ways a consumer
gets basecoat alongside sheen:

1. **Bundled** — sync from this repo and pull the vendored `basecoat-*` assets
   directly (single source, pinned together).
2. **Independent** — the consumer syncs basecoat from its own upstream via
   `.basecoat.yml` and syncs sheen via `.sheen.yml`. Because namespaces never
   collide (`basecoat-*` vs `sheen-*`), both resolve cleanly.

The vendored tree is read-only here and excluded from sheen's validation and
metadata scans (spec 05 §1).
