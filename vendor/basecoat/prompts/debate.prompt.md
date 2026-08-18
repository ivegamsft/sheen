---
description: "Run a structured design debate: generate 2-4 options, score each against this product's PRODUCT.md design principles using a weighted matrix, and produce an ADR-style decision record. Prefix any design decision with 'debate:' to get a principled, traceable choice. Works in Copilot CLI, VS Code Copilot Chat, and any editor with Copilot Chat support."
model: claude-sonnet-4.6
tools: ["codebase", "changes"]
---

# debate:

**How to invoke:**

```text
debate: <design question or tradeoff>
```

**Examples:**

```text
debate: should we use container queries or CSS Grid for our card layout?
debate: inline vs modal state for the address-edit flow
debate: should tokens use scale names (gray-500) or semantic names (on-surface)?
debate: hamburger menu vs persistent nav for mobile breakpoint
debate: single page vs wizard for our 7-step onboarding form
debate: should error messages be inline or in a toast?
```

---

## What This Prompt Does

Structures a design decision as a weighted matrix debate: each option is scored
against the product's design principles from `PRODUCT.md`, a winner is declared,
and the result is written as a decision record. The output is traceable, reviewable,
and can be committed as a lightweight ADR.

---

## Workflow

### Step 1 — Load product context

Read `PRODUCT.md` from the repository root. Extract:

- **Design Principles** — the numbered strategic rules used as scoring criteria
- **Users** — who the decision affects (anchors trade-offs to real people)
- **Accessibility & Inclusion** — the floor (hard constraint, not a scored criteria)
- **Anti-references** — disqualifiers: if an option resembles an anti-reference, flag it

If `PRODUCT.md` is not present, proceed with the sheen framework defaults and
recommend creating one with `design: create PRODUCT.md for this product`.

### Step 2 — Frame the question

Restate the debate question as a crisp, decision-shaped statement:

```
Question: [one sentence — what decision is being made?]
Context:  [one sentence — what situation makes this decision necessary?]
Constraint: [any hard constraints — e.g., "must meet WCAG 2.2 AA"]
```

Ask the user to confirm the framing before proceeding, or continue if the
framing is unambiguous.

### Step 3 — Generate options

Produce 3 options (or 2 if the question is binary, 4 if the space is genuinely
multi-dimensional). Each option must be:

- **Named**: a short label used throughout the matrix (e.g., "Inline", "Modal", "Drawer")
- **Described**: 2–3 sentences on what it is and how it works
- **Differentiated**: no two options should be essentially the same

If the user provided options in their request, use those. Add a "hybrid" option
if the provided options have a viable combination.

### Step 4 — Score the matrix

Score each option against each Design Principle from `PRODUCT.md` on a 1–5 scale:

| Score | Meaning |
|-------|---------|
| 5 | Strongly satisfies this principle |
| 4 | Satisfies this principle |
| 3 | Neutral |
| 2 | Minor tension with this principle |
| 1 | Conflicts with this principle |

Apply weights to the principles if the context suggests some matter more for
this decision. Default: equal weights. State the weights explicitly.

**Accessibility check (hard gate):** Before scoring, evaluate each option
against the WCAG level stated in `PRODUCT.md`. If an option fails the
accessibility floor, mark it `❌ DISQUALIFIED (a11y)` and exclude it from
the winner selection.

**Output format:**

```
## Weighted Decision Matrix

Principles (equal weight unless noted):
  P1. Effortless over configurable   [weight: 1.0]
  P2. Calm information density       [weight: 1.0]
  P3. Personal to context            [weight: 0.8]
  P4. Familiar conventions           [weight: 1.0]
  P5. Complete and coherent          [weight: 1.2]  ← higher weight for this decision

|            | P1 | P2 | P3 | P4 | P5 | Weighted Total |
|------------|----|----|----|----|----|----|
| Option A   |  4 |  5 |  3 |  4 |  5 |  21.0          |
| Option B   |  3 |  3 |  5 |  3 |  2 |  15.4          |
| Option C   |  5 |  4 |  3 |  5 |  4 |  21.0          |

Winner: Option A / Option C (tie — see tiebreak below)
```

**Tiebreak:** If two options score identically, apply the Users section from
`PRODUCT.md` as the tiebreak: which option serves the primary user better in
the most common case?

### Step 5 — Write the decision record

Produce an ADR-style decision record in Markdown:

```markdown
## Decision Record — [Short Title]

**Date:** YYYY-MM-DD
**Status:** Proposed
**Deciders:** [leave blank for the team to fill in]

### Question
[Restated question from Step 2]

### Context
[Context sentence from Step 2]

### Options considered

**[Option A name]**
[Description]
Score: P1=4, P2=5, P3=3, P4=4, P5=5 → Weighted: 21.0

**[Option B name]**
[Description]
Score: P1=3, P2=3, P3=5, P4=3, P5=2 → Weighted: 15.4
❌ Also: conflicts with anti-reference [name] — [reason]

**[Option C name]**
[Description]
Score: P1=5, P2=4, P3=3, P4=5, P5=4 → Weighted: 21.0

### Decision
**[Winning option name]** — [one sentence rationale anchored to the top principle]

### Consequences
- ✅ [What becomes easier or better]
- ⚠️  [What becomes harder or must be managed]
- 🔲 [Follow-up action required]

### Accessibility note
[Confirmation of WCAG compliance for the chosen option, or required remediation]
```

### Step 6 — Offer to save

Ask the user if they want to save the decision record:

```
Save this as docs/decisions/[slug].md? (yes / no / paste-only)
```

If yes, write the file. If no, return the decision record as output only.

---

## Output format rules

- **Always** show the matrix before the winner — the reasoning must be visible.
- **Never** declare a winner without a matrix — debate: is not an opinion prompt.
- **Never** omit the accessibility gate — WCAG conformance is a hard floor, not a tradeoff.
- **Never** hedge the final decision with "it depends" unless the matrix is a genuine
  tie after the tiebreak, in which case state: "Tied — team must decide based on
  [specific context signal]."
- Decision records are written in **past tense** ("was chosen", "was rejected")
  only after the user confirms. While proposing, use present tense.

---

## Tips

- Use `debate:` when you need a record, not just an answer. For a quick
  directional answer use `design:` instead.
- Commit decision records to `docs/decisions/` — they become the product's
  design history and ground future AI sessions.
- The matrix weights can be overridden: `debate: [weight P5=2.0] inline vs modal…`
- For token naming debates, the `design-tokens` skill's naming conventions are
  an additional hard constraint alongside the design principles.
- Chain with `design:` after the debate: `debate: → design: implement [winner]`
