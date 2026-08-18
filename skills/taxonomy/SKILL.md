---
name: taxonomy
compatibility: [github-copilot-cli]
description: "Use when designing controlled vocabularies, category hierarchies, or tag schema definitions. USE FOR: controlled vocabulary design, category hierarchy rules, tag schema definition. DO NOT USE FOR: entity relationship modeling, component state specs."
category: ia
metadata:
  category: ia
  maturity: beta
  audience: [designer, developer]
  pillar: ia
allowed-tools: []
---

# taxonomy

Define taxonomies and controlled vocabularies.

## Workflow
1. Define user intents and findability tasks for the information space.
2. Model entities, categories, and relationships for retrieval and navigation.
3. Build candidate structures and labeling systems for target channels.
4. Stress-test ambiguity and overlap using representative content examples.
5. Finalize governance rules for growth, naming, and change control.

## Guardrails
- Do not optimize taxonomy for internal jargon over user language.
- Do not leave overlapping categories without clear disambiguation rules.
- Do not change IA without migration implications for navigation/search.
- Do not publish IA recommendations without concrete placement examples.

## Output
- IA/taxonomy package: structure map, definitions, and naming rules.
- Ambiguity and edge-case register with resolution policy.

## Delegates / pairs with
- ontology
- information-architecture
