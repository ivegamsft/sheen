# Lexicon Skill — Audit Mode Workflow

Run periodically (or before releases) to detect vocabulary drift and taxonomy inconsistencies.

**Invoke:**

```text
Use the lexicon skill in audit mode. Load .lexicon.md and scan all docs and assets
for vocabulary drift, taxonomy inconsistencies, and tone violations. Report findings
by severity with file references.
```

## Step 1 — Load `.lexicon.md`

If `.lexicon.md` does not exist, run define mode first. Do not proceed without it.

## Step 2 — Scan for Violations

Use [`audit-checklist.md`](../audit-checklist.md) as your structured checklist.
For each check, grep the relevant file set and record violations with file and line number.

**Vocabulary checks:**

- Grep for deprecated terms and synonyms listed in the vocabulary registry
- Flag any use of a synonym where the canonical term should appear
- Flag any capitalization variant that contradicts the canonical spelling

**Taxonomy checks:**

- Compare category labels in asset frontmatter to the taxonomy defined in `.lexicon.md`
- Flag assets with no category or with a category not in the registry
- Flag assets whose category doesn't match their content

**Ontology checks:**

- Search for references to concepts not defined in the ontology
- Flag relationships implied in content that contradict the ontology
  (e.g., a skill described as "an agent")

**Theme/vibe checks:**

- Scan headings and lead sentences for tone markers
- Flag document-level tone mismatches (e.g., a casual opener in a formal governance doc)
- Flag anti-vocabulary usage

## Step 3 — Report

Use the findings format from [`audit-checklist.md`](../audit-checklist.md).
Group by severity. Include file path and line number for every finding.
End with a summary count: `N Critical, N High, N Medium, N Low`.

## When to Run Audit Mode

- Before any public release
- After merging large documentation PRs
- When contributors report confusion about what terms mean
- As part of a quality gate (run alongside linting and link checking)
- After discovering inconsistencies (e.g., three spellings of one product name)
