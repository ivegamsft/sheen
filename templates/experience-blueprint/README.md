# Experience Blueprint Templates

> Use these templates when running the `experience-blueprint` skill (see
> `specs/10-experience-blueprint.spec.md`, implemented via ADR-010). They are
> reasoning aids and starter structure, not a mandated file format — copy the
> concepts and relationships into whatever representation the downstream
> project already uses (Markdown, YAML, JSON, a database, or a design tool).

## Files

| Template | Use for |
|---|---|
| `experience-index.md` | The canonical logical index: identifiers, relationships, sources, decisions, and open questions (spec §5). |
| `archetypes.md` | The eight initial composable archetypes and the custom-archetype declaration format (spec §7). |
| `audit-workflow.md` | Evidence register, confidence, 0-4 maturity scoring, and findings format for **audit mode** (spec §8, §10). |
| `generation-workflow.md` | Brief, candidate-direction exploration, and dependency-ordered artifact generation for **generate mode** (spec §9). |
| `handoff.md` | Source-linked summary and implementation handoff package (spec §9 step 7, §13). |

## How to use these templates

1. Confirm mode (audit or generate) and scope before picking a template.
2. Start from the downstream's accepted design system, evidence, and product
   decisions (spec §4.1) — these templates are the fallback, not the source
   of truth.
3. Populate the experience index first; every other artifact links back to
   its stable IDs.
4. Delegate brand, voice, IA, layout, page, wireframe, and component detail to
   the owning specialist skill listed in `experience-blueprint/SKILL.md`
   rather than duplicating it here.
5. Validate the result with `scripts/audit-experience-blueprint.ps1` before
   treating the blueprint as complete (spec §12).
