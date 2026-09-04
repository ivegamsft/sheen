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

Audit or generate a product's complete, implementation-neutral experience
contract: brand, voice, IA, layouts, pages, wireframes, navigation, and flows
as one traceable model. Implements `specs/10-experience-blueprint.spec.md`.

## Workflow
1. Select mode. **Audit:** inventory routes, screens, navigation, content,
   styles, copy, analytics, and existing docs; record each source in an
   evidence register (`templates/experience-blueprint/audit-workflow.md`).
   **Generate:** capture the brief, audiences, constraints, and select a
   primary + supporting archetype (`templates/experience-blueprint/archetypes.md`).
2. Populate the experience index (`templates/experience-blueprint/experience-index.md`):
   stable IDs, relationships, sources, decisions, and open questions.
3. Delegate each domain artifact to its owning specialist skill (see
   Delegates below) instead of authoring it inline.
4. For generation, produce at least two candidate IA/layout directions when
   material uncertainty exists and resolve them with `design-debate`.
5. Validate cross-references, required states, responsive coverage, and
   archetype-required moments (`scripts/audit-experience-blueprint.ps1`).
6. For audits, score each dimension 0-4 with evidence and confidence, and log
   findings with severity, affected artifact IDs, and a recommendation.
7. Produce a source-linked summary and handoff
   (`templates/experience-blueprint/handoff.md`) in the downstream's chosen
   representation.

## Guardrails
- Do not reimplement brand, IA, accessibility, component, or frontend
  expertise already owned by another skill; index and relate their output.
- Do not claim a page, flow, or state is absent without supporting evidence.
- Do not silently replace an accepted brand, token, IA, or component decision.
- Do not prescribe language, framework, file format, or rendering technology.

## Output
- Experience index with stable, unique artifact IDs and relationships.
- Brand, voice, IA, layout, page, wireframe, navigation, and flow references
  (audit: observed; generate: proposed) produced by the owning specialists.
- Audit only: evidence register, 0-4 maturity scores, prioritized findings.
- Generate only: brief, candidate directions, resolved direction, handoff.

## Delegates / pairs with
- `brand-identity`, `brand-voice-tone`, `design-tokens`, `theming`
- `information-architecture`, `navigation-design`, `taxonomy`
- `layout-grid-spacing`, `responsive-design`, `content-hierarchy`
- `app-layout-catalog` (app-specific logical layout gallery, spec 12)
- `wireframing`, `user-research`, `ux-writing`
- `component-spec`, `pattern-library`, `ui-states-interaction`
- `app-component-catalog` (app-specific logical component gallery, spec 11)
- `design-audit`, `design-system-audit`, `web-usability-review`
- `accessibility-audit`, `secure-ux`
- `design-exploration`, `design-debate`
- `design-handoff`, `design-to-code`
- agent: `experience-architect`
