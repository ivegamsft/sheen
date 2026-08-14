# Design context

> The shared design values, influence sources, and craft bar that sheen assets
> appeal to during reviews, debates, and audits. Distilled from root
> `SPEC.md` §2 and made durable here and in
> `references/`. `sheen-10-core-design-principles` loads these values as ambient
> context.

## Design values

sheen adopts a named value set adapted from **Windows 11** and **Material 3**, so
every skill and agent can appeal to shared principles in `design-review` and
`design-debate`:

| Value | Meaning in a review |
|---|---|
| **Effortless** | The obvious path is the easy path; reduce steps, choices, and cognitive load. |
| **Calm** | Quiet by default; motion, color, and density serve the task, not decoration. |
| **Personal** | Respect user context, preferences, locale, and accessibility settings. |
| **Familiar** | Reuse established patterns and platform conventions; minimize surprise. |
| **Complete + Coherent** | Cover the full journey (empty, loading, error, success) with one consistent system. |

## Usability backbone

The **Nielsen Norman Group** ten heuristics are the evaluation checklist for
`web-usability-review`, `usability-mapping`, and the design-review agents:

1. Visibility of system status
2. Match between system and the real world
3. User control and freedom
4. Consistency and standards
5. Error prevention
6. Recognition rather than recall
7. Flexibility and efficiency of use
8. Aesthetic and minimalist design
9. Help users recognize, diagnose, and recover from errors
10. Help and documentation

## Influence sources

| Source | What sheen takes from it | Pillar |
|---|---|---|
| impeccable *(inspiration)* | The craft bar — "invisible when right" | Craft |
| brand.github.com | Brand identity: logo, color, type, voice, imagery | Brand |
| Nielsen Norman Group | Usability heuristics + UX-research rigor | Web usability |
| HubSpot web-design guidelines | Practical web usability heuristics | Web usability |
| uistyleguide.com / style-guide examples | How to structure a style guide / pattern library | Style guide |
| Material 3 | Token-driven foundations, components, states, motion, theming | Design system |
| Fluent 2 | Global + alias token model, high-contrast theming, state tokens | Design system |
| Windows 11 design principles | The named value set + materials, geometry, layering | Craft / design system |
| Leading studios (Sapient, Seán Halpin, DesignRush picks) | Aesthetic bar: layout, motion, storytelling, positive space | Craft / aesthetic |

## Conformance bar

The influences set the *aesthetic* bar; formal standards set the *conformance* bar
and become `checks.json` gates (see `specs/08-standards-conformance.spec.md`):

- **W3C WCAG 2.2 AA** + **WAI-ARIA / APG**
- **ISO 9241** (usability / human-centered design) + **ISO/IEC 25010**
- **ISO 24495-1** (plain language)
- **W3C DTCG** design tokens
- **BCP 47 / Unicode CLDR-ICU** for i18n
- **OWASP** (ASVS / Top 10) for secure UX

Machine-testable thresholds (e.g. WCAG contrast) are hard `error` gates; the rest
are advisory `warn`s plus process guidance in the relevant skills and instructions.
