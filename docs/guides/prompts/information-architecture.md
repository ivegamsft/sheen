# Prompt Guide — 🗂️ Information Architecture

**Agent:** `@information-architect`  
**Pillar:** Information Architecture  
**Invoke:** `/sheen ia`, `/sheen taxonomy`, `/sheen ontology`, `/sheen content-hierarchy`, `/sheen multilingual`, `/sheen i18n-framework`

The `information-architect` owns content structure, navigation hierarchy, taxonomy,
controlled vocabularies, ontologies, and multilingual content frameworks.
It composes `information-architecture`, `navigation-design`, `taxonomy`, and `ontology`.

---

## Agent-level prompts

### Full IA design for a new product

```
/sheen ia
Design the full information architecture for a B2B procurement SaaS.
Users: procurement managers, approvers, and finance reviewers.
Key objects: purchase requests, vendors, contracts, budgets, approvals.
Produce: sitemap, content model, primary navigation, taxonomy for categories
and status labels, and a controlled vocabulary for shared terms.
```

**Flow:**
1. Clarify user roles, key tasks, and primary objects.
2. Run `information-architecture` — build sitemap and content model.
3. Run `navigation-design` — design primary and secondary nav.
4. Run `taxonomy` — classify objects and status values.
5. Run `ontology` — define shared term vocabulary and relationships.
6. Return: sitemap · nav spec · taxonomy · controlled vocabulary.

**Output shape:**
```
🗺️ Sitemap (text hierarchy)
📄 Content model (objects × attributes × relationships)
🔗 Navigation spec (primary, secondary, contextual)
🏷️ Taxonomy (categories, tags, status labels)
📖 Controlled vocabulary (term → definition → synonyms → related terms)
```

---

## Skill-by-skill reference

### `information-architecture` — Sitemap and content model

**Intent:** `sitemap-ia`  
**Keywords:** ia, information-architecture, sitemap

**When to use:** Defining a new product's structure, restructuring a growing product,
or auditing navigation against user mental models.

**Sample prompts:**

```
/sheen ia
Build a sitemap for a developer documentation portal covering 3 SDKs,
a REST API reference, a CLI reference, tutorials (beginner/intermediate/advanced),
and a changelog. Users: external developers. Primary task: find a method fast.
Optimise for search-first discovery.
```

```
/sheen ia
Audit the current sitemap for our settings area. We have 47 settings pages across
6 categories. Users report they can't find billing and notification settings.
Identify IA issues and propose a restructured hierarchy with rationale.
```

**Flow:**
1. Identify user tasks and content types.
2. Cluster content by user mental model (card-sort simulation).
3. Build top-level hierarchy and second-level structure.
4. Flag any deep nesting (>3 levels) or orphan pages.

**Output:** Sitemap (indented text) · Mental model rationale · Problem areas · Restructure proposal

---

### `taxonomy` — Classification system design

**Intent:** `ia-taxonomy-design`  
**Keywords:** taxonomy, classification, hierarchy, category

**Sample prompt:**

```
/sheen taxonomy
Design a taxonomy for a marketplace platform with: product categories
(electronics, home, clothing, sports), seller types (individual, brand, certified),
and condition labels (new, refurbished, used-good, used-fair).
Include: term names, definitions, parent/child relationships, and guidance for
edge cases (e.g. a product that spans two categories).
```

```
/sheen taxonomy
Review our current tag taxonomy (attached list of 340 tags). Identify:
duplicates, near-duplicates (semantic), orphaned tags (used <3 times),
and structural gaps. Propose a cleaned taxonomy with merge/retire/add actions.
```

**Flow:**
1. Define scope: what objects does the taxonomy describe?
2. Identify top-level facets (category, status, type, etc.).
3. Define terms at each level with definitions and examples.
4. Add edge-case guidance (multi-category, ambiguous cases).

**Output:** Taxonomy hierarchy (indented) · Term definitions · Edge-case rules · Merge/retire/add action list

---

### `ontology` — Controlled vocabulary and concept relationships

**Intent:** `ontology-design`  
**Keywords:** ontology, vocabulary, controlled-vocabulary

**Sample prompt:**

```
/sheen ontology
Design a controlled vocabulary for a clinical trial management system.
Key concepts: trial, site, participant, visit, adverse event, protocol amendment.
For each concept: preferred term, definition, synonyms/aliases, related concepts,
broader term, narrower terms, and usage notes.
```

```
/sheen ontology
Map the relationships between these domain objects in our HR system:
Employee, Department, Role, Grade, Policy, Leave Request, Payroll Run.
Produce: entity relationship descriptions, shared property definitions,
and a glossary of field names that must be consistent across modules.
```

**Flow:**
1. Identify primary concepts and objects.
2. Per concept: preferred term, definition, synonyms, scope notes.
3. Define relationships (is-a, part-of, related-to) between concepts.
4. Flag naming inconsistencies across modules or teams.

**Output:** Concept glossary table · Relationship map (text) · Synonym/alias register · Inconsistency list

---

### `content-hierarchy` — Content model and priority

**Intent:** `content-hierarchy`  
**Keywords:** content-hierarchy, content-model, content-type

**Sample prompt:**

```
/sheen content-hierarchy
Define a content model for an article page in a media product.
Content types needed: feature article, news brief, opinion piece, explainer.
For each type: required fields, optional fields, field types, max lengths,
media requirements, and SEO metadata. Include a priority order for
progressive disclosure on mobile.
```

**Flow:**
1. Define each content type and its purpose.
2. Per type: list required/optional fields with types and constraints.
3. Define display priority for each breakpoint.
4. Flag shared fields that should be a common schema.

**Output:** Content type schemas · Field definitions table · Display priority matrix · Shared field register

---

### `multilingual` — Multilingual content framework

**Intent:** `multilingual-i18n`  
**Keywords:** multilingual, i18n, l10n, locale, translation

**Sample prompt:**

```
/sheen multilingual
Design a multilingual content framework for a product launching in
EN, FR, DE, JA, and AR. Cover: string externalisation strategy,
pluralisation rules per locale, date/number/currency formatting,
RTL layout considerations for AR, and a translation workflow.
```

**Flow:**
1. Define supported locales and their script/direction requirements.
2. Define string externalisation format (i18n JSON, ICU messages).
3. Per locale: pluralisation rules, date format, number format, currency.
4. Define RTL layout switch strategy.
5. Define translation workflow (source language, review, QA gate).

**Output:** Locale capability matrix · String format spec · RTL layout checklist · Translation workflow diagram (text)

---

### `i18n-framework-mapping` — i18n library and RTL mapping

**Intent:** `i18n-framework-mapping`  
**Keywords:** i18n-framework, rtl, bidi, language-support

**Sample prompt:**

```
/sheen i18n-framework
We use React with react-i18next. Map our framework's i18n capabilities to
our locale requirements (EN, JA, AR). For AR: define the CSS logical properties
strategy (margin-inline-start vs margin-left), Bidi algorithm considerations,
and component-level RTL audit checklist.
```

**Flow:**
1. Map framework i18n API to required locale features (plurals, dates, RTL).
2. Define CSS logical property substitutions for RTL layouts.
3. Audit component types that need RTL-specific treatment.
4. Produce an RTL readiness checklist.

**Output:** Framework capability map · CSS logical property substitution list · Component RTL audit checklist
