# Token Build & CI Integration

Use this pattern when token correctness and repeatable builds matter more than
the breadth of synced AI assets.

## Flow

1. Sync the token set you need.
2. Build or transform the tokens into the platform format you ship.
3. Run token validation in CI.
4. Fail the pipeline on missing references, contrast gaps, or theme drift.

## Reference checks

- `scripts/validate-tokens.ps1`
- `checks.json`
- `.github/workflows/ci.yml`
- `.github/workflows/docs.yml`

## Practical guidance

- pin `ref` to a release tag for stable CI inputs
- keep semantic tokens as the source of truth
- avoid bypassing semantic tokens with raw color stops

## What good looks like

- token output is deterministic
- theme coverage is complete enough for the product surface
- docs and CI agree on the same naming and reference rules
