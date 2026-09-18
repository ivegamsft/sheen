---
name: ontology
compatibility: [github-copilot-cli]
description: "Use when modeling content-domain entities, semantic relationships, or attribute constraints for IA, search, and findability. USE FOR: content-domain ontology modeling, semantic relationship mapping, attribute constraint definitions for navigation and retrieval. DO NOT USE FOR: physical relational database schema design, backend data modeling, flat category taxonomies, brand color work."
category: ia
metadata:
  category: ia
  maturity: beta
  audience: [designer, developer]
  pillar: ia
allowed-tools: []
---

# ontology

Model content-domain semantic entities, attributes, and relationships for IA, search, and findability.

## Workflow

1. Define user intents and findability tasks for the information space.
2. Separate content/domain semantics from physical storage or relational-schema concerns.
3. Model entities, categories, and relationships for retrieval and navigation.
4. Build candidate structures and labeling systems for target channels.
5. Stress-test ambiguity and overlap using representative content examples.
6. Finalize governance rules for growth, naming, and change control.

## Guardrails

- Do not optimize taxonomy for internal jargon over user language.
- Do not leave overlapping categories without clear disambiguation rules.
- Do not change IA without migration implications for navigation/search.
- Do not publish IA recommendations without concrete placement examples.
- Do not design physical database schemas, tables, indexes, migrations, or persistence-layer models; hand those off to data-tier or backend expertise.

## Output

- IA/taxonomy package: structure map, definitions, and naming rules.
- Ambiguity and edge-case register with resolution policy.

## Delegates / pairs with

- taxonomy
- information-architecture
- data-tier for physical database schema design
