# Lexicon Audit Checklist

Use this checklist in lexicon skill audit mode. Work through each section,
grep for violations, and record findings in the format at the end of this file.

---

## Prerequisites

- [ ] `.lexicon.md` exists and is current
- [ ] Scope defined: which directories to scan (default: `docs/`, `agents/`, `skills/`, `instructions/`)
- [ ] Baseline: note the last audit date from `.lexicon.md` section 6

---

## Section 1: Vocabulary Checks

### 1.1 Canonical spelling enforcement

For each term in the vocabulary registry, grep for all known variants:

```bash
# Example: check for "Base Coat" (space) when canonical is "BaseCoat"
grep -rn "Base Coat" docs/ agents/ instructions/ skills/

# Example: check for lowercase "basecoat" in prose (not code/paths)
grep -rn "\bbasecoat\b" docs/
```

| Check | Severity |
|---|---|
| Deprecated term appears in any doc or asset | 🔴 Critical |
| Synonym used where canonical term is required | 🟠 High |
| Capitalization variant in a heading or title | 🟠 High |
| Capitalization variant in body text | 🟡 Medium |
| Informal shorthand in formal documentation | 🟡 Medium |

### 1.2 Anti-vocabulary check

Grep for each phrase listed in the anti-vocabulary section of `.lexicon.md`:

```bash
grep -rni "[anti-vocab term]" docs/ agents/ instructions/
```

| Check | Severity |
|---|---|
| Anti-vocabulary term in a heading | 🔴 Critical |
| Anti-vocabulary term in a description or frontmatter | 🟠 High |
| Anti-vocabulary term in body prose | 🟡 Medium |

### 1.3 Consistency across files

Same concept referred to by different names across different files:

```bash
# Grep for both variants and compare file counts
grep -rl "[variant A]" docs/ | wc -l
grep -rl "[variant B]" docs/ | wc -l
```

| Check | Severity |
|---|---|
| Same concept has 3+ distinct names across the repo | 🔴 Critical |
| Same concept has 2 names across the repo | 🟠 High |
| Inconsistent plural/singular usage for same term | 🟡 Medium |

---

## Section 2: Taxonomy Checks

### 2.1 Asset category coverage

Every asset (agent, skill, instruction) must have a `category` frontmatter field
matching a top-level category in the taxonomy:

```bash
# Find assets missing category
grep -rL "category:" agents/ skills/ instructions/

# Find assets with unrecognized categories
grep -rh "category:" agents/ skills/ instructions/ | sort | uniq -c | sort -rn
```

| Check | Severity |
|---|---|
| Asset has no category | 🟠 High |
| Asset has a category not in the taxonomy registry | 🟠 High |
| Asset category doesn't match its content | 🟡 Medium |
| Category name uses wrong casing | 🟡 Medium |

### 2.2 Classification consistency

Assets of the same type should use the same set of categories:

```bash
grep -h "category:" agents/*.agent.md | sort | uniq
```

| Check | Severity |
|---|---|
| Agents use categories not used by any other agent (one-off) | 🟡 Medium |
| Category used for <3 assets (may need consolidation) | ⚪ Low |

---

## Section 3: Ontology Checks

### 3.1 Undefined concept references

Concepts referenced in docs but not defined in the ontology:

```bash
# Search for references to key ontology terms
grep -rn "\bis-a\b\|\bdepends on\b\|\btype of\b" docs/
```

| Check | Severity |
|---|---|
| Relationship claimed in docs contradicts ontology | 🔴 Critical |
| Concept referenced repeatedly but not in ontology | 🟠 High |
| Concept in ontology never referenced in docs | ⚪ Low (orphan — consider removing) |

### 3.2 Mutual exclusion violations

Concepts defined as mutually exclusive are used interchangeably:

```bash
# Example: check for "skill" used where "agent" is meant
grep -n "skill" agents/*.agent.md | grep -v "allowed_skills\|skills/" | head -20
```

| Check | Severity |
|---|---|
| Mutually exclusive terms used as synonyms in formal docs | 🟠 High |
| Mutually exclusive terms confused in examples | 🟡 Medium |

---

## Section 4: Theme and Vibe Checks

### 4.1 Tone register

Scan headings and first sentences of each major doc for tone markers:

| Check | Severity |
|---|---|
| Heading uses exclamation mark in a formal doc | 🟠 High |
| Marketing superlatives ("best", "amazing", "revolutionary") | 🟠 High |
| Anti-reference tone pattern (e.g., overly casual in governance doc) | 🟠 High |
| Inconsistent formality across sections of same doc | 🟡 Medium |
| Mixed first/second person within a single doc | 🟡 Medium |

### 4.2 Anchoring metaphor consistency

If metaphors are defined in `.lexicon.md`, check they're used consistently:

| Check | Severity |
|---|---|
| Metaphor contradiction (two different metaphors for same concept) | 🟠 High |
| Off-brand metaphor used (contradicts anti-references) | 🟠 High |
| Metaphor overused (appears in >50% of pages) | ⚪ Low |

---

## Section 5: Naming Convention Checks

```bash
# File naming pattern check (example: kebab-case for docs)
find docs/ -name "*.md" | grep -v "^[a-z0-9-/._]*$"

# Agent naming pattern check (should be kebab-case)
find agents/ -name "*.agent.md" | grep -vE "^agents/[a-z0-9-]+\.agent\.md$"
```

| Check | Severity |
|---|---|
| File name violates naming convention | 🟡 Medium |
| Asset name violates naming convention | 🟡 Medium |
| Heading casing inconsistent with convention | ⚪ Low |

---

## Findings Report Format

Use this format for the audit output:

```markdown
## Lexicon Audit — [Project Name]

**Date:** YYYY-MM-DD
**Scope:** docs/, agents/, skills/, instructions/
**Baseline:** Last audit YYYY-MM-DD ([N] findings)

### Summary

| Severity | Count |
|---|---|
| 🔴 Critical | N |
| 🟠 High | N |
| 🟡 Medium | N |
| ⚪ Low | N |
| **Total** | **N** |

### Critical findings

#### [VOCAB-001] Deprecated term in heading
**File:** `docs/guides/consumer-sync.md:12`
**Found:** "Base Coat" (two words)
**Required:** "BaseCoat" (camelcase per .lexicon.md §1)
**Fix:** Replace with canonical form

### High findings

...

### Medium findings

...

### Low / informational

...

### Recommendations

1. [Highest-impact fix first]
2. ...
```

---

## Severity Reference

| Severity | When to use |
|---|---|
| 🔴 Critical | Wrong term in a public heading or description; deprecated term in active use; ontology contradiction |
| 🟠 High | Wrong term in body prose; taxonomy violation; tone misalignment in formal docs |
| 🟡 Medium | Inconsistency between files; mild tone drift; naming convention violation |
| ⚪ Low | Single-file inconsistency; orphaned ontology concept; minor casing issue |
