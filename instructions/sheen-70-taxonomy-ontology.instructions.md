---
name: sheen-70-taxonomy-ontology
compatibility: [github-copilot-cli]
description: "Path-scoped controlled vocabulary, relationship, and taxonomy rules for design-system assets."
applyTo: "**/*.md,**/*.mdx,**/.github/skills/**,**/.github/agents/**,**/.github/instructions/**,**/skills/**,**/agents/**,**/instructions/**,**/tokens/**,**/docs/**,**/.lexicon.md,**/sheen-metadata.json"
metadata:
  band: 70
  layer: taxonomy-ontology
---

# Taxonomy and Ontology

Apply these rules when naming, classifying, or relating any sheen asset, token, or
design concept. Consistent taxonomy makes assets discoverable and relationships
explicit; inconsistent taxonomy creates drift and duplication.

## Canonical vocabulary

The `.lexicon.md` file is the single source of truth for all canonical terms. When
writing skill output, documentation, or asset names:

- Use the canonical term from `.lexicon.md`, not a synonym.
- If a term is missing from `.lexicon.md`, add it there before using it.
- Do not introduce aliases or abbreviations that are not registered in `.lexicon.md`.
- The `lexicon` skill audits drift; run it when new terms are added.

Key canonical terms (do not substitute):

| Use this | Not this |
|---|---|
| token | variable, constant, setting |
| skill | plugin, extension, library |
| instruction | rule, guideline, policy |
| agent | bot, assistant, module |
| consumer | user, client, adopter |
| sync | install, deploy, import |
| drift | lag, stale |
| theme | mode, skin |
| pillar | category, band (band is instruction-layer only) |

## Asset naming conventions

- **Skills:** `skills/<kebab-case-name>/` -- the folder name equals the `name`
  frontmatter field.
- **Agents:** `<role>.agent.md` -- singular noun or hyphenated noun phrase.
- **Instructions:** `sheen-<NN>-<layer>-<topic>.instructions.md` -- band, layer,
  then topic; all kebab-case.
- **Tokens:** `category.scale-or-role[.variant]` -- see `sheen-20-tokens-naming`.
- **Documents:** kebab-case file names; no spaces or underscores.

## Asset relationships and pillar classification

Every skill and agent must declare its `pillar` in frontmatter. The pillar taxonomy:

| Pillar | Covers |
|---|---|
| foundations | Token system, color, type, space, motion, elevation |
| brand | Identity, voice, logo, imagery |
| information-architecture | Structure, navigation, taxonomy |
| web-usability | Heuristics, responsive, usability review |
| accessibility | WCAG, ARIA, color contrast, inclusive design |
| content | Microcopy, i18n, localization, plain language |
| security-ux | Secure UX patterns, consent, safe error states |
| components | Component specs, states, patterns |
| lifecycle | Design-audit, bootstrap, update, suggest, debate, handoff |
| governance | Style guide, design review, craft quality, meta skills |

Skills that span multiple pillars should be classified under their primary
pillar and cross-reference the others in their `description`.

## Ontological relationships

Document explicit relationships between assets:

- **Composes:** a skill or agent that calls another (declare in frontmatter or body).
- **Delegates to:** a skill that hands off deeper work to a more specialized skill.
- **Requires:** an asset that cannot function without another being present.
- **Conflicts with:** two assets that govern overlapping concerns (should be rare;
  resolve by clarifying scope boundaries).

## Design concept classification

When classifying a design concept or recommendation:

- Assign it to exactly one pillar.
- Name the governing instruction layer (band 10-90) that applies.
- Identify whether it is a token concern (tier: core/semantic/theme), a component
  concern (anatomy/state/interaction), a content concern, or a process concern.

## Review lens

Before finalizing any asset name or classification, ask:

- Is every term used in `.lexicon.md`? If not, has it been added?
- Is the asset name kebab-case and consistent with naming conventions?
- Is the pillar classification correct and singular?
- Are relationships to other assets documented (composes, delegates, requires)?
- Would a new contributor understand this classification without additional context?
