# Validation Checks Reference

Core validation surfaces:

- `checks.json` for rule definitions
- `scripts/validate-tokens.ps1` for token schema/reference/contrast gating
- `.github/workflows/ci.yml` for lint and token jobs
- `.github/workflows/docs.yml` for strict docs build
- `docs/reference/model-capabilities.json` for model capability governance used in
  skill and agent audits

Use these files as the authoritative source for enforcement behavior.
