---
name: experience-blueprint
compatibility: [github-copilot-cli]
description: "Implementation-neutral orchestrator for a product's end-to-end UI/UX contract. USE FOR: audit an existing application's full experience and produce evidence-backed findings, generate a new experience from a product brief and archetype, coordinate brand/voice/IA/layout/page/flow specialists into one coherent contract, validate cross-artifact relationships and state coverage, produce a source-linked handoff for implementation. DO NOT USE FOR: brand-only identity work (brand-identity), IA-only sitemap/taxonomy work (information-architecture), single-component specification (component-spec), app-specific component or layout gallery maintenance alone (app-component-catalog, app-layout-catalog), writing runtime UI code (design-to-code, frontend-dev)."
category: lifecycle
metadata:
  category: lifecycle
  maturity: draft
  audience: [designer, developer]
  pillar: lifecycle
allowed-tools: []
---
# Experience Blueprint

Audit or generate one traceable, implementation-neutral brand/voice/IA/layout/page/wireframe/navigation/flow contract.

## Workflow
1. Read and apply the [orchestration contract](references/orchestration-contract.md), mode checklists, shared templates, and validation/handoff requirements.
2. Audit: inventory sources/evidence. Generate: capture brief/audiences/constraints and primary/supporting archetypes.
3. Index stable IDs, relationships, sources, decisions, questions; delegate domain artifacts to their owners.
4. For material generation uncertainty, create ≥2 IA/layout candidates and resolve via `design-debate`.
5. Validate references, states, responsive coverage, and archetype moments. Audit dimensions 0–4 with evidence/confidence and severity-ranked findings.
6. Hand off source-linked output; reference `theming`'s selected revision, decision/readiness evidence, and affected catalog entries.

## Guardrails
- Index specialist outputs; never duplicate their expertise or the theme catalog.
- No unsupported absence claims or silent replacement of accepted brand/token/IA/component decisions.
- No inferred write rights; no prescribed language, framework, format, or renderer.

## Output
- Downstream experience index with unique IDs/relationships and specialist artifact references (observed/proposed).
- Audit: evidence register, 0–4 scores, prioritized findings.
- Generate: brief, candidates, resolved direction, source-linked handoff.

## Delegates / pairs with
- `brand-identity`, `brand-voice-tone`, `design-tokens`, `theming`
- `information-architecture`, `navigation-design`, `taxonomy`
- `layout-grid-spacing`, `responsive-design`, `content-hierarchy`
- `app-layout-catalog` (logical layout gallery, spec 12)
- `wireframing`, `user-research`, `ux-writing`
- `component-spec`, `pattern-library`, `ui-states-interaction`
- `app-component-catalog` (logical component gallery, spec 11)
- `design-audit`, `design-system-audit`, `web-usability-review`
- `accessibility-audit`, `secure-ux`
- `design-exploration`, `design-debate`
- `design-handoff`, `design-to-code`
- agent: `experience-architect`
