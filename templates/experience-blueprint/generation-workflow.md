# Generation Workflow: Brief to Blueprint

> For **generate mode** (spec §9). Produce artifacts in dependency order:
> brief → brand/voice → IA → layouts → pages → wireframes → flows. Use the
> existing project's decisions and assets first (spec §4.1); do not silently
> replace an accepted brand, token, IA, or component contract.

## 1. Brief (spec §6.1)

| Field | Value |
|---|---|
| Product outcome and non-goals | |
| Primary audiences, jobs, and contexts | |
| Platforms, breakpoints, and input modes | |
| Content and data constraints | |
| Accessibility, localization, privacy, security constraints | |
| Success measures | |
| Unresolved assumptions | |

## 2. Archetype selection

Primary archetype: `[archetype-id]` — see `archetypes.md`.
Supporting archetype(s): `[archetype-id, ...]`.
Rationale: [why this composition fits the brief].

## 3. Candidate directions

Generate **at least two** candidate IA/layout directions whenever material
design uncertainty exists. Do not skip this step to save time.

| Direction | IA approach | Layout approach | Key tradeoff |
|---|---|---|---|
| A | | | |
| B | | | |

## 4. Direction resolution

Run `design-debate` over the candidate directions using weighted criteria
(usability impact, accessibility risk, implementation complexity, delivery
speed, long-term maintainability). Record:

- Selected direction and confidence.
- Rejected direction(s) and why.
- Trigger conditions that would revisit this decision.

## 5. Delegate artifact generation, in order

1. **Brand/voice** — delegate to `brand-identity`, `brand-voice-tone`,
   `design-tokens`, `theming`; reference `DESIGN.md` /
   `AESTHETIC-DIRECTION.md` instead of duplicating token values.
2. **IA** — delegate to `information-architecture`, `navigation-design`,
   `taxonomy`.
3. **Layouts** — delegate to `layout-grid-spacing`, `responsive-design`, and
   `app-layout-catalog` for the app-specific logical layout gallery
   (reuse/extend/create selection, region and navigation placement).
4. **Pages** — delegate to `content-hierarchy` and `app-component-catalog`
   for the app-specific logical component/pattern selection.
5. **Wireframes** — delegate to `wireframing`; low fidelity unless the brief
   explicitly requests visual comps.
6. **Flows** — delegate to `user-research`/`ux` journey templates; every
   step MUST link to a page ID or a declared external touchpoint.

## 6. Validation before handoff

Run `scripts/audit-experience-blueprint.ps1` and confirm:

- cross-references resolve (layouts, pages, flows);
- state coverage and responsive behavior are complete;
- specialist constraints (brand, a11y, secure-ux) are satisfied;
- archetype-required moments are represented.

## 7. Handoff

Produce the downstream handoff using `handoff.md` and identify remaining
implementation dependencies (design-to-code, frontend-dev, or another
downstream-chosen path).
