# Lexicon Skill — Define Mode Workflow

Run once (or after major scope changes) to establish the project lexicon.
Output is written to `.lexicon.md` in the project root.

**Invoke:**

```text
Use the lexicon skill in define mode. Scan the project and establish the vocabulary,
taxonomy, ontology, and brand voice. Persist to .lexicon.md.
```

## Step 1 — Explore

Before asking any questions, scan the project autonomously:

- **README and docs**: what words are used to describe the project? What terms are introduced?
- **Asset frontmatter**: what names, categories, and descriptions exist? Are they consistent?
- **Existing glossaries or style guides**: any prior vocabulary work to build on?
- **Navigation and headings**: what classification structure does the project use?
- **Anti-patterns already present**: inconsistent spellings, synonym drift, vague category names

Record what is clear and what is ambiguous before proceeding.

## Step 2 — Clarify the Gaps

Ask only what cannot be inferred from the codebase:

**Vocabulary:**

- Is there an official name (single canonical spelling) vs. informal variants in use?
- Are there terms that should never appear in output (deprecated, off-brand, incorrect)?
- Any terms specific to this domain that need explicit definition?

**Taxonomy:**

- How should assets/concepts be grouped at the top level?
- Are there sub-categories? What is the nesting depth?
- Are any categories temporary (sprint-specific) vs. permanent?

**Ontology:**

- Which concepts depend on which? (e.g., "a skill is used by an agent")
- Are there inheritance relationships? (e.g., "a task agent is a type of agent")
- Are there exclusion relationships? (e.g., "instructions are not skills")

**Theme and vibe:**

- Describe the project's personality in 3 words.
- What should it explicitly NOT sound like? (anti-references)
- Formal or conversational? Dense or accessible? Technical or domain-agnostic?
- Any metaphors or analogies that anchor the brand — and any to avoid?

## Step 3 — Write `.lexicon.md`

Synthesize exploration findings and answers into the template.
If `.lexicon.md` already exists, update each section in place.

See [`lexicon-template.md`](../lexicon-template.md) for the full file format.

## When to Run Define Mode

- Starting a new project and establishing its identity
- After rebranding, renaming, or a major scope change
- When multiple authors are working on the same system and speaking differently
- Before a public launch where coherence matters
