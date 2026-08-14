---
name: design-tokens
compatibility: [github-copilot-cli]
description: "Use when this skill is the right fit for the request. Author and evolve DTCG token source-of-truth. USE FOR: creating or editing core/semantic tokens, adding token aliases safely, maintaining token schema integrity. DO NOT USE FOR: choosing brand palette strategy alone, running full-repo UX audits."
category: foundation
metadata:
  category: foundation
  maturity: stable
  audience: [designer, developer]
  pillar: foundations
allowed-tools: []
---
# Design Tokens

Create and maintain the canonical token system under `tokens/`.

## Workflow
1. Identify the target tier (core, semantic, or theme override) and impacted roles.
2. Add or update token entries with `$type`, `$value`, and `$description`.
3. Wire semantic aliases to core primitives and preserve naming conventions.
4. Validate references, tier discipline, and contrast gates with token validation.
5. Summarize token changes and compatibility implications.

## Guardrails
- Do not place alias references in `tokens/core/`.
- Do not add theme-only keys absent from semantic tier.
- Do not rename published semantic keys without explicit breaking-change intent.

## Output
- Updated token JSON files with valid DTCG structure.
- Change summary with expected impact on themes and consumers.

## Delegates / pairs with
- `theming`, `color-system`, `color-contrast-check`
- `motion-elevation`, `typography`

