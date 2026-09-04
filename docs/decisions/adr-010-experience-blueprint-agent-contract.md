# ADR-010 — Experience Blueprint as Agent Contract and Orchestrator

| Field | Value |
|---|---|
| **Date** | 2026-09-04 |
| **Status** | Accepted |
| **Deciders** | sheen maintainers |
| **Supersedes** | — |
| **Superseded by** | — |

## Context

Issue #163 asks sheen to support a complete application-experience workflow:
audit an existing UI/UX or generate a new one, covering branding, information
architecture, voice, page layout, wireframes, pages, navigation, and user flows.
It also asks for reusable structures suited to different experience types such
as a home page, campaign splash, commerce product, dashboard, or control tower.

Sheen already has specialist capabilities for each domain. What is missing is
the relationship contract that makes their outputs one coherent experience.
Without that contract, an agent can produce individually plausible artifacts
that disagree about route names, page purpose, layout regions, terminology,
navigation destinations, or flow steps.

The decision must preserve specialist ownership, support both audit and
generation, prevent conceptual drift, remain implementation-neutral, and stay
extensible as new application archetypes are added.

## Decision criteria

| Criterion | Weight |
|---|---:|
| End-to-end completeness and traceability | 25% |
| Reuse of existing specialist capabilities | 20% |
| Audit and generation parity | 15% |
| Archetype extensibility and composition | 15% |
| Drift prevention and validation | 10% |
| Long-term maintainability | 10% |
| Downstream adoption cost | 5% |

Scores use a 1–5 scale.

## Options considered

### Position A — One monolithic experience-design skill

Create one large skill that directly owns brand, IA, voice, layouts,
wireframes, page definitions, and flows.

- Simple entry point and low initial implementation cost.
- Duplicates existing specialist workflows and routing boundaries.
- A single prompt/output is difficult to validate or update incrementally.
- Audit and generation would likely diverge into separate unstructured reports.
- Archetype additions would increase the skill's size and ambiguity.

### Position B — Agent-only choreography over existing skills

Add an agent that calls existing skills and merges their prose outputs, with no
new canonical source schema.

- Maximizes reuse and keeps domain expertise in the current skills.
- Offers flexible orchestration for different applications.
- Leaves relationships implicit in prompts and agent memory.
- Cannot reliably detect orphan pages, broken flow references, conflicting
  navigation, or missing page states.
- Results vary by model and session, making audits difficult to compare.

### Position C — Canonical logical Experience Blueprint plus orchestrator

Define a format-neutral logical blueprint contract, then add a thin
orchestrator that delegates each domain to the existing specialist skill or
agent. Provide composable experience-archetype reasoning templates and require
source-linked documentation in the downstream's chosen representation.

- Gives audit and generation one stable output contract.
- Preserves specialist ownership and existing routing.
- Enables cross-reference, state-coverage, and orphan validation.
- Supports partial updates without regenerating the entire experience.
- Lets archetypes define required experience moments without prescribing
  brand styling or fixed components.
- Requires the most design work because the agent contract, templates,
  validation behavior, routing, and generation workflow all need to be added.

## Weighted comparison

| Criterion | Weight | A | B | C |
|---|---:|---:|---:|---:|
| Completeness and traceability | 25 | 3 | 3 | 5 |
| Specialist reuse | 20 | 1 | 5 | 5 |
| Audit/generation parity | 15 | 2 | 3 | 5 |
| Archetype extensibility | 15 | 2 | 4 | 5 |
| Drift prevention | 10 | 1 | 1 | 5 |
| Maintainability | 10 | 1 | 3 | 4 |
| Adoption cost | 5 | 4 | 4 | 3 |
| **Weighted score / 5** | **100** | **2.05** | **3.45** | **4.75** |

## Decision

**Adopt Position C.** Sheen will define the Experience Blueprint agent
contract in Spec 10. The agent will produce:

1. a canonical logical experience index;
2. related brand, voice, IA, layout, page, wireframe, navigation, and flow
   artifacts;
3. deterministic delegation to existing specialist capabilities;
4. reusable, composable experience archetypes;
5. relationship validation and source-linked documentation.

The same core model is used in audit and generation modes. Audit mode adds
evidence and findings; generation mode starts from a brief and candidate
directions. This prevents an audit report from becoming a dead-end artifact.

The decision does **not** prescribe programming language, framework, file
format, repository path, design tool, rendering engine, storage model, or
documentation technology. Downstreams choose those implementation details.

Archetypes are structural presets, not aesthetic templates. A `control-tower`
archetype can require situation awareness, prioritization, drill-down,
resolution, and escalation moments, but it cannot prescribe a color palette,
component library, or exact dashboard layout.

## Sensitivity and fallback

Position C remains preferred even if adoption cost is weighted four times
higher: its validation, traceability, and parity advantages still outweigh the
extra files.

If the full contract proves too heavy in early consumer trials, the fallback is
not Position B. The fallback is a **minimum blueprint profile** that keeps the
same concepts and relationships but requires only the brief, IA, page
inventory, and flows.

## Consequences

- **Positive:** Existing design skills gain a shared integration contract
  without losing domain ownership.
- **Positive:** Audit findings can link directly to the page, layout, flow, and
  evidence they concern.
- **Positive:** Downstream agents can implement from an explicit, source-linked
  contract rather than reverse-engineering disconnected prose and diagrams.
- **Positive:** Experience archetypes can evolve independently of branding and
  tokens.
- **Cost:** The feature needs contract checks, reasoning templates,
  orchestrator routing, documentation behavior, and representative scenarios.
- **Risk:** A blueprint can create false confidence if generated without user
  research or evidence. Audit mode therefore requires evidence and confidence;
  generate mode requires explicit assumptions and unresolved questions.
- **Risk:** Specialists may duplicate source content in the blueprint.
  Validation and templates must prefer references to `DESIGN.md`,
  `AESTHETIC-DIRECTION.md`, `.lexicon.md`, component inventory, and pattern
  library.

## Related

- `specs/10-experience-blueprint.spec.md`
- [Experience Blueprint guide](../guides/experience-blueprints.md)
- ADR-007 (populated catalogs prevent drift)
- ADR-008 (`AESTHETIC-DIRECTION.md` generated artifact)
- Issue #163
