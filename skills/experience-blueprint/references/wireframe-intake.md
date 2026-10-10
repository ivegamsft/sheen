# Wireframe intake in either blueprint mode

Accept `sheen-wireframes/v1` as prototype evidence without replacing the
experience index. Validate the original model with the sibling `wireframing`
helper. Supply separately approved original model baselines from trusted
immutable revisions; compare complete decoded models before mappings.
Missing baselines block attached handoffs; embedded digests are not independent
trust. Record approval/revision provenance; the caller owns baseline authenticity.
Use the handoff attachment's structured `baseline` revision, approval evidence
and canonical digest; verify the digest against the separate original. The
sample records synthetic evidence only, not actual product approval.
Then resolve page/screen/flow IDs unchanged. Distinct screen states
may share one page. Keep accepted layout/theme/component decisions authoritative.
Audit simulations are proposed behavior, not proof of the running application.

Delegate packaging to sibling `design-handoff` and read its local
`references/wireframe-contract.md`. Its complete
`templates/wireframe-blueprint.json` illustrates the existing reference
blueprint with an optional attachment, not a new mandatory schema.
Its `scripts/validate-wireframe-handoff.py` checks model and relationships
without writing artifacts. Sync both `design-handoff` and `wireframing` to
use it; do not assume source-repository scripts are available downstream.

Require screen-to-implementation/spec references, positional input/action
behavior/dependency mappings, ordered blueprint flow-step mappings and reasons
for omitted states. Preserve source provenance, simulation boundaries,
responsive/accessibility limits and visual/task review evidence/status.
Missing mappings block validated handoff; pending review remains a bounded
draft. Run blueprint-wide validation independently in the downstream's format.

Mock inputs, actions and success/error states are not real validation,
persistence, authentication, payment, network or business side effects.
Never copy prototype controls/CSS/JS into production as implemented behavior.
Route accepted component/spec mappings to `design-to-code` for scaffolds and
business/integration logic to `frontend-dev`. Structural validity is not
production sign-off, user validation, WCAG certification or write authorization.
