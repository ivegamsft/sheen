# Lexicon Skill — Agent Pairing and BaseCoat Reference

## Agent Pairing

This skill is designed to be used alongside:

- **`guidance-reviewer`** — Reviews instructions and agent files for consistency;
  use the lexicon audit output to focus its attention
- **`tech-writer`** — Uses the vocabulary and tone sections to write coherent docs
- **`agent-designer`** — Uses the taxonomy and ontology to place new agents
  in the right category with consistent naming
- **`guidance-author`** — Uses vocabulary registry to avoid deprecated terms
  when authoring new instructions

## BaseCoat Reference Lexicon

BaseCoat's own `.lexicon.md` is the canonical example of this skill applied to itself.
It defines the vocabulary, taxonomy, ontology, and vibe for all BaseCoat assets.

Key entries:

| Term | Canonical form | Do not use |
|---|---|---|
| Product name (prose) | **BaseCoat** | Base Coat, base-coat, basecoat |
| Repo identifier | **basecoat** | Base Coat, BaseCoat, base-coat |
| Install path only | **base-coat** | All other contexts |
| Asset group | **agents**, **skills**, **instructions**, **prompts** | modules, plugins, extensions |
| Adopting a repo | **sync** | install, deploy, bootstrap (informal only) |
| Team that reviews memory | **steward** | admin, moderator, owner |

Personality words: **precise · pragmatic · enterprise-grade**

Anti-references: paint/chemistry product feel, startup hype, academic formality
