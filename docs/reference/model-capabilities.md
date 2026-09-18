# Model Capabilities Reference

This repository maintains an auditable model capability catalog at:

- `docs/reference/model-capabilities.json`

## Purpose

Use this artifact for skill and agent governance reviews that need to verify:

1. model ID availability for a specific host and surface
2. configurable reasoning support for that surface
3. tool and context capabilities
4. the difference between task metadata and provider parameters

## Ownership and update process

1. **Owner:** `basecoat-sheen maintainers`
2. **When to update:** after runtime/model changes, model deprecations, or new
   model adoption in this repository.
3. **How to update:** edit `model-capabilities.json` in the same PR as the
   skill/agent change that depends on the capability.
4. **Review expectation:** PRs that introduce model-specific routing guidance
   must reference updated capabilities in this file.

## Host-aware selection contract

1. Filter by `host` and `surface`; do not treat one surface as universal.
2. Intersect with effective organization and user entitlement when runtime data
   is available.
3. Match task capability requirements before cost or latency.
4. Emit `reasoning_effort` only when the selected model, host, surface, and
   authenticated runtime support the exact value.
5. Treat unknown-to-catalog model IDs as unverified for this repo, not globally
   unavailable.

`reasoning_depth` describes task complexity. It is not a provider parameter and
must never be copied automatically into `reasoning_effort`.

## Current evidence

The current catalog is based on GitHub Copilot CLI session tool descriptors and
repository asset inspection captured on 2026-09-18. Provenance records the
Copilot CLI version, session identifier, audited repository revision, and
vendored BaseCoat release/commit used for the prompt-pin audit. It records:

- `interactive-cli` evidence for task/tool invocation surfaces.
- `agent-frontmatter` as a separate surface with unknown availability,
  reasoning-effort, tool, and context support unless a model assignment is
  explicitly verified there.
- `skill-frontmatter` as a separate surface; source Sheen skills currently have
  no model pins.
- `prompt-frontmatter` as a separate surface; vendored BaseCoat v4.5.0 prompts
  currently contain five `claude-sonnet-5` pins and one `gpt-5.4-mini` pin.
- source Sheen agents, skills, and prompts currently have no model pins, so no
  global replacement is required.

Family names such as `sonnet` are aliases/preferences unless the exact
host-specific model ID is documented. Preserve intentional inheritance and
report unknown IDs separately from fixed-effort or unsupported assignments.
