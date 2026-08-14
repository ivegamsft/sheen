# Model Capabilities Reference

This repository maintains an auditable model capability catalog at:

- `docs/reference/model-capabilities.json`

## Purpose

Use this artifact for skill and agent governance reviews that need to verify:

1. model ID availability
2. configurable reasoning support
3. tool and context capabilities

## Ownership and update process

1. **Owner:** `basecoat-sheen maintainers`
2. **When to update:** after runtime/model changes, model deprecations, or new
   model adoption in this repository.
3. **How to update:** edit `model-capabilities.json` in the same PR as the
   skill/agent change that depends on the capability.
4. **Review expectation:** PRs that introduce model-specific routing guidance
   must reference updated capabilities in this file.
