# Prompt Guide — ✅ Governance

**Agent:** `@design-reviewer`  
**Pillar:** Governance  
**Invoke:** `/sheen review`, `/sheen debate`, `/sheen audit`, `/sheen craft`, `/sheen pattern`, `/sheen secure-ux`, `/sheen regression`, `/sheen style-guide`, `/sheen suggest`, `/sheen update`

The `design-reviewer` owns craft-bar critiques, structured design debates, pattern library
governance, secure UX reviews, visual regression strategy, and style guide authorship.
It composes `design-review`, `design-debate`, and `craft-quality`.

---

## Agent-level prompts

### Structured design tradeoff (debate)

```
/sheen debate
We need to choose between two navigation approaches for a complex B2B product:
Option A: persistent sidebar with sections and sub-sections.
Option B: top nav with contextual side panels per section.
Criteria: cognitive load, scalability to 50+ pages, mobile adaptation, and
implementation cost. Weight cognitive load highest.
Produce a weighted tradeoff matrix and recommend one option with an ADR.
```

**Flow:**
1. Frame the decision with one-sentence problem statement, constraints, non-goals.
2. Define evaluation criteria and weights.
3. Generate ≥3 options (including conservative baseline).
4. Score each option per criterion with evidence.
5. Identify key risks and reversibility for top two options.
6. Recommend one option, document fallback trigger, produce ADR entry.

**Output shape:**
```
📋 Decision brief
  ├── Problem statement + constraints
  ├── Weighted criteria table
  └── Option comparison matrix

🔍 Risk & reversibility analysis
  └── Top 2 options: risks, blast radius, rollback cost

✅ Recommendation
  ├── Chosen option + confidence level
  ├── Fallback trigger condition
  └── ADR-style summary entry
```

---

## Skill-by-skill reference

### `design-review` — Artifact critique

**Intent:** `craft-critique` (via design-review)  
**Keywords:** review, critique, craft, polish

**When to use:** Single-artifact review against design principles, standards, or
a specific brief. Use before design handoff or stakeholder presentation.

**Sample prompts:**

```
/sheen review
Review these three card component variants against the sheen design principles:
Effortless (minimal cognitive load), Calm (no unnecessary emphasis),
Complete+Coherent (all required information present without gaps).
Flag issues per variant with severity and specific corrective actions.
```

```
/sheen review
Critique this onboarding modal against our design contract:
- Must complete in ≤3 steps
- Must have a visible skip option
- Must not use more than 2 CTAs per step
- Must meet WCAG AA contrast
Return pass/fail per contract item with evidence.
```

**Flow:**
1. Clarify scope, governing standards, and acceptance criteria.
2. Evaluate the artifact against each criterion.
3. Per finding: severity (critical/major/minor), evidence, remediation.
4. Return a governance report with decision log.

**Output:** Governance report · Findings table (criterion × status × evidence) · Decision log · Follow-up owners

---

### `design-debate` — Structured tradeoff analysis

**Intent:** `debate-design-options`  
**Keywords:** debate, tradeoff, adr, compare, options

**Sample prompts:**

```
/sheen debate
Compare two empty-state designs for a data table:
Option A: illustration + headline + CTA.
Option B: text-only + CTA (lighter weight).
Criteria: brand expression, cognitive load, implementation cost, adaptability
to different empty-state contexts (no data, no results, error, loading).
Recommend one with an ADR-style record.
```

```
/sheen adr
Write an ADR for our decision to adopt a design token system over hard-coded
values in our component library. Context: legacy codebase, 4 themes required,
team of 3 engineers. Document: decision, rationale, alternatives rejected,
consequences (positive and negative).
```

**Flow:**
1. Frame decision + problem statement.
2. Define weighted criteria.
3. Generate ≥3 options (conservative, recommended, speculative).
4. Score options per criterion with evidence + confidence.
5. Sensitivity check on top criterion.
6. Recommend + ADR entry.

**Output:** Weighted criteria table · Option matrix · Sensitivity check · Recommended option · ADR summary

---

### `craft-quality` — Craft-bar review

**Intent:** `craft-critique`  
**Keywords:** critique, craft, polish, craft-bar

**Sample prompt:**

```
/sheen craft
Run a craft-bar review of our redesigned settings page.
Check: spacing consistency (8px grid), typographic hierarchy (3 levels max),
component usage (are we using the right sheen components?), visual weight
balance, and information density. Flag any craft issues with severity.
```

**Flow:**
1. Review against spacing grid (flag violations).
2. Check typographic hierarchy (max 3 levels per screen).
3. Validate component usage against pattern library.
4. Assess visual weight and information density.
5. Return annotated findings list.

**Output:** Craft findings list (issue, element, severity) · Grid violation summary · Component usage audit

---

### `design-audit` — Design system health audit

**Intent:** `design-audit`  
**Keywords:** audit, design-audit, system-audit

**Sample prompt:**

```
/sheen design-audit
Audit our product UI against the sheen design system. Sample 20 representative
screens. Check: are components from the design system or custom? Are token values
used or are hard-coded hex/px values present? Are spacing values on the 8px grid?
Return a system adoption rate and gap list.
```

**Flow:**
1. Define audit scope and sample size.
2. Per screen: inventory components (system vs. custom), token usage, spacing violations.
3. Calculate adoption rate per dimension.
4. Produce a prioritised gap list.

**Output:** Adoption rate scorecard · Custom component inventory · Hard-coded value count · Gap priority list

---

### `pattern-library` — Pattern governance

**Intent:** `pattern-library-review`  
**Keywords:** pattern, pattern-library, component-pattern

**Sample prompts:**

```
/sheen pattern
Review our current pattern library for gaps. We have 28 components.
Missing categories we've identified: data visualisation, empty states,
inline editing, and batch actions. For each missing category: define the
pattern contract (what variants, states, and use cases it must cover).
```

```
/sheen pattern
We have three different date-picker implementations in the product.
Consolidate them into one canonical pattern with: usage rules,
variant definitions (date only, date range, date+time), and a deprecation
path for the non-canonical implementations.
```

**Flow:**
1. Audit existing patterns for coverage gaps.
2. For new patterns: define contract (variants, states, use cases).
3. For duplicates: define canonical pattern + deprecation path.

**Output:** Gap analysis · Pattern contract definitions · Duplicate consolidation plan · Deprecation timeline

---

### `secure-ux` — Security-aware UX review

**Intent:** `secure-ux-review`  
**Keywords:** secure-ux, privacy-ux, security-design

**Sample prompts:**

```
/sheen secure-ux
Review our password reset flow for security UX issues. Check:
- Does the error message distinguish "account not found" from "wrong password"?
- Is the reset token single-use and time-limited (communicated to users)?
- Is the new-password form free of autocomplete vulnerabilities?
- Does success state avoid confirming whether the email exists?
```

```
/sheen privacy-ux
Review our data export and account deletion flows for privacy UX compliance.
Criteria: GDPR Art. 17 (right to erasure) — user must be able to complete
deletion without contacting support. Flag any dark patterns that obstruct deletion.
```

**Flow:**
1. Identify security/privacy criteria applicable to the flow.
2. Evaluate each touchpoint for information leakage, dark patterns, or confusion.
3. Per finding: issue, risk level (critical/major/minor), remediation.

**Output:** Security UX findings table · Privacy compliance checklist · Dark pattern list · Remediation guidance

---

### `visual-regression` — Visual regression strategy

**Intent:** `visual-regression`  
**Keywords:** regression, visual-regression, snapshot

**Sample prompt:**

```
/sheen regression
Define a visual regression testing strategy for our component library.
Tool: Playwright + Percy. Coverage: all 28 components × light/dark/high-contrast themes.
Define: snapshot scope (full component vs. states), threshold (pixel diff tolerance),
CI integration point, and failure triage workflow.
```

**Flow:**
1. Define snapshot scope and threshold policy.
2. Map components × themes × states to snapshot count.
3. Define CI gate (when regression runs, pass/fail criteria).
4. Define triage workflow (who reviews diffs, approval process).

**Output:** Snapshot scope table · CI integration spec · Triage workflow · Threshold policy

---

### `style-guide-authoring` — Style guide documentation

**Intent:** `style-guide-authoring`  
**Keywords:** style-guide, document-guidelines, component-spec-page

**Sample prompt:**

```
/sheen style-guide
Write a style guide entry for our Button component.
Include: overview, variants (primary/secondary/ghost/danger), sizes (sm/md/lg),
states (default/hover/focus/active/disabled/loading), usage do/don't,
accessibility requirements, and token references. Format: Markdown, suitable
for our docs site.
```

**Flow:**
1. Define component overview and variants.
2. Document all sizes and states.
3. Write usage do/don't rules.
4. Add accessibility requirements and token references.
5. Format in Markdown for the docs site.

**Output:** Style guide Markdown entry · Variant table · State documentation · Token reference list

---

### `design-suggest` / `design-update` — Suggestions and revisions

**Intents:** `design-suggest`, `design-update`  
**Keywords:** suggest, recommend, update, revision

**Sample prompts:**

```
/sheen suggest
Suggest improvements for our notification banner component.
Current issues: too many variants causing decision fatigue (7 types),
inconsistent icon usage, and unclear hierarchy between info/warning/error.
Propose a consolidated set with rationale.
```

```
/sheen update
We're updating our button component to add a new "loading" state and deprecate
the "outline-danger" variant. Produce: updated component spec, deprecation notice
(with migration path), and changelog entry.
```

**Flow (suggest):** Diagnose current pain points → generate options → evaluate → recommend with rationale.  
**Flow (update):** Ingest current spec → apply changes → update affected states → produce changelog entry.

**Output (suggest):** Improvement options · Recommendation with rationale · Open questions  
**Output (update):** Updated component spec · Deprecation notice + migration path · Changelog entry
