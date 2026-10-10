# Experience Orchestration and Handoff Contract

Read for both audit and generation. Implements the source repository's
[spec 10](https://github.com/ivegamsft/sheen/blob/main/specs/10-experience-blueprint.spec.md).
The shared templates/tools linked below live in that repository; they are
not relative paths inside a synced skill folder.

## Workflow
1. Select mode. **Audit:** inventory routes, screens, navigation, content,
   styles, copy, analytics, and existing docs; record each source in an
   evidence register ([audit workflow](https://github.com/ivegamsft/sheen/blob/main/templates/experience-blueprint/audit-workflow.md)).
   **Generate:** capture the brief, audiences, constraints, and select a
   primary + supporting archetype ([archetypes](https://github.com/ivegamsft/sheen/blob/main/templates/experience-blueprint/archetypes.md)).
2. Populate the [experience index](https://github.com/ivegamsft/sheen/blob/main/templates/experience-blueprint/experience-index.md):
   stable IDs, relationships, sources, decisions, and open questions.
3. Delegate each domain artifact to its owning specialist skill (see
   Delegates in [SKILL.md](../SKILL.md)) instead of authoring it inline.
4. For generation, produce at least two candidate IA/layout directions when
   material uncertainty exists and resolve them with `design-debate`.
5. Validate cross-references, required states, responsive coverage, and
   archetype-required moments (source-checkout tool:
   [audit-experience-blueprint.ps1](https://github.com/ivegamsft/sheen/blob/main/scripts/audit-experience-blueprint.ps1)).
6. For audits, score each dimension 0-4 with evidence and confidence, and log
   findings with severity, affected artifact IDs, and a recommendation.
7. Produce a source-linked summary and handoff
   ([handoff](https://github.com/ivegamsft/sheen/blob/main/templates/experience-blueprint/handoff.md)) in the downstream's chosen
   representation.
   Reference the selected theme revision, decision/readiness evidence and affected
   catalog entries from `theming`; do not reproduce its catalog or infer write rights.

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
