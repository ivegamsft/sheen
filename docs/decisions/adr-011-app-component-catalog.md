# ADR-011 — Neutral Seed Plus App-Specific Logical Component Gallery

| Field | Value |
|---|---|
| **Date** | 2026-09-04 |
| **Status** | Accepted |
| **Deciders** | sheen maintainers |
| **Supersedes** | — |
| **Superseded by** | — |

## Context

Issue #164 asks for an agent that can audit, generate, and document the logical
components used by one application. The resulting gallery must tell agents
where a component should and should not appear, how it composes, what data and
states it needs, how it adapts responsively, and how it relates to page
layouts.

The catalog needs a starting point, but each downstream has its own design
system. A starting point must prevent blank-page invention without turning a
popular public library into Sheen's default design system.

## Reference review

[Component Gallery](https://component.gallery/) is useful because it treats a
component gallery as a reference, not an off-the-shelf library. Its strongest
reusable ideas are normalized component concepts, aliases across design
systems, nested composition, multiple real-world examples, and explicit
guidance on when and when not to use a component. Its own about page cautions
against copying popular approaches without research.

[shadcn/ui](https://ui.shadcn.com/) is useful because it presents primitives,
composed blocks, dependencies, themes, and registries as discoverable items
that downstreams own and adapt. Its reusable lesson is the layered,
composable, browsable catalog model. React, Tailwind CSS, source-file
distribution, registry JSON, component APIs, and visual design are
implementation choices and are not adopted by this decision.

## Decision criteria

| Criterion | Weight |
|---|---:|
| Honors each downstream design system | 25% |
| Reliable component selection and placement | 20% |
| Audit/generation parity | 15% |
| Composition and dependency clarity | 15% |
| Discoverability and documentation | 10% |
| Drift prevention | 10% |
| Implementation neutrality | 5% |

Scores use a 1–5 scale.

## Options considered

### Position A — Adopt a public component library as the default

Start every downstream from one public library or gallery and map the
application to its names and structures.

- Fastest starting point and many examples.
- Forces external naming and assumptions onto different products.
- Conflates structural inspiration with visual and code adoption.
- Makes non-web and non-matching design systems second-class.
- Encourages copying instead of evidence-based design.

### Position B — Add app metadata directly to Sheen's shared inventory

Extend the upstream component inventory with every downstream's usage,
placement, data, and implementation details.

- Reuses the existing inventory and avoids a new catalog concept.
- Mixes universal/shared maturity with application-specific decisions.
- Creates cross-consumer noise and ownership conflicts.
- Cannot express two applications making validly different choices.

### Position C — Neutral seed vocabulary plus app-specific logical gallery

Use a small implementation-neutral vocabulary as a discovery checklist, then
derive an app-specific logical catalog from the downstream design system,
Experience Blueprint, evidence, and product needs. Keep optional code/design
bindings separate from the logical contract.

- Avoids a blank page without imposing a default design system.
- Gives audit and generation one contract.
- Supports aliases, composition, dependencies, restrictions, and selection.
- Allows multiple implementations of one logical component.
- Keeps the gallery useful for agents even when the technology changes.
- Requires disciplined metadata and relationship validation.

## Weighted comparison

| Criterion | Weight | A | B | C |
|---|---:|---:|---:|---:|
| Downstream design-system fit | 25 | 1 | 3 | 5 |
| Selection and placement | 20 | 2 | 3 | 5 |
| Audit/generation parity | 15 | 2 | 3 | 5 |
| Composition clarity | 15 | 3 | 2 | 5 |
| Discoverability | 10 | 5 | 3 | 5 |
| Drift prevention | 10 | 2 | 2 | 5 |
| Implementation neutrality | 5 | 1 | 3 | 5 |
| **Weighted score / 5** | **100** | **2.10** | **2.75** | **5.00** |

## Decision

**Adopt Position C.** The component capability will specify agent behavior for:

1. starting from the downstream's own design system and evidence;
2. using a neutral seed vocabulary only to detect gaps and normalize language;
3. maintaining an app-specific logical component catalog;
4. separating logical components from optional implementation bindings;
5. documenting selection, placement, composition, styling abstractions, data,
   states, accessibility, responsive behavior, and provenance;
6. presenting the catalog as a composable gallery in the downstream's chosen
   representation.

Sheen will not prescribe component code, a framework, a CSS system, a registry
format, a design tool, or a gallery implementation.

## Consequences

- **Positive:** A downstream keeps ownership of its design system while gaining
  a rigorous starting taxonomy and selection contract.
- **Positive:** Agents can distinguish synonyms, variants, drift, patterns,
  layout regions, and genuinely new components.
- **Positive:** Technology migrations can change bindings without invalidating
  component intent and usage rules.
- **Cost:** App teams must curate their logical catalog; it cannot be inferred
  reliably from source code alone.
- **Risk:** A seed vocabulary can become a de facto required inventory.
  Spec 11 therefore requires removing, renaming, combining, or extending it to
  match the application.
- **Risk:** Gallery previews can overshadow usage guidance. Visual examples are
  explicitly optional and non-normative.

## Related

- `specs/11-app-component-catalog.spec.md`
- [App Component Catalog guide](../guides/app-component-catalogs.md)
- ADR-007 (shared component inventory and pattern catalog)
- ADR-010 (Experience Blueprint agent contract)
- Issues #164 and #170
