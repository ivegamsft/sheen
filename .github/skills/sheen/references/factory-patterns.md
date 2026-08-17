# Sheen Router — Factory Composition Patterns

Multi-agent patterns for design requests that span more than one pillar or require
parallel evidence gathering before synthesis. Each pattern includes: trigger conditions,
composition structure, sub-agent prompt templates, coordinator merge instructions,
and exit criteria.

---

## Pattern 1 — Parallel Audit

**When to use:** A surface or component requires simultaneous review across accessibility,
usability, and governance pillars before a release gate or design review board.

**Trigger conditions:**
- User says "full design review", "pre-release design audit", or "multi-pillar check"
- Three or more distinct pillar concerns exist for the same artifact

**Composition:**

```
coordinator (@design-reviewer)
├── sub-agent A → @accessibility-auditor  [worktree-a]
├── sub-agent B → @ux-designer            [worktree-b]
└── sub-agent C → @design-reviewer        [worktree-c] (craft-quality + design-audit skills)
```

**Sub-agent prompt template:**

```text
# Sub-agent A — Accessibility
Context: {artifact description}
Skill: accessibility-audit
Task: Run a WCAG 2.2 AA conformance check covering contrast, focus order, ARIA roles,
and keyboard traps. Return findings table with severity (critical/major/minor) and
remediation owner (design vs. engineering). Do not defer to the other agents.

# Sub-agent B — Usability
Context: {artifact description}
Skill: web-usability-review + wireframing (as reference)
Task: Evaluate against the 5 heuristics: Effortless, Calm, Personal, Familiar, Complete+Coherent.
Return a scored heuristic table with evidence and improvement suggestions.

# Sub-agent C — Craft & Governance
Context: {artifact description}
Skill: craft-quality + design-audit
Task: Review for craft-bar conformance (spacing consistency, type scale, component usage),
cross-referencing the pattern-library. Return issues with severity and pattern reference.
```

**Coordinator merge instructions:**
1. Collect all three findings tables.
2. De-duplicate overlapping findings (same element, different pillar view).
3. Produce a unified risk matrix ordered by severity × blast-radius.
4. Assign each finding to a pillar owner; escalate critical cross-pillar items.
5. Emit a single decision package with: consolidated findings, pillar-owner assignments,
   release recommendation (go / hold / conditional), and follow-up ticket stubs.

**Exit criteria:** All three sub-agents return findings; consolidated risk matrix produced;
release recommendation documented.

---

## Pattern 2 — Serial Decision-Chain

**When to use:** A design decision must be made before implementation specs can be produced.
The output of one skill is the required input for the next.

**Trigger conditions:**
- User says "decide and spec", "design then hand off", or "ADR then implementation"
- A `design-debate` output is the precondition for `design-handoff`

**Composition:**

```
Step 1: @design-reviewer  [design-debate skill]
         ↓ ADR output
Step 2: @ux-designer      [design-handoff + component-spec skills]
         ↓ implementation spec
Step 3: (optional) @accessibility-auditor  [accessibility-audit skill]
         ↓ spec conformance check
```

**Prompt chain template:**

```text
# Step 1 — design-debate
Problem: {decision scope}
Options: {list at least 3}
Constraints: {constraints}
Task: Produce a weighted tradeoff matrix and recommend one option. Output an ADR-style
decision record with: chosen option, decision rationale, fallback trigger, risks.

# Step 2 — design-handoff (receives ADR from Step 1)
Chosen design: {Step 1 ADR decision}
Task: Produce an implementation-ready spec including: component anatomy, token references,
interaction states, responsive behaviour, and handoff annotations.

# Step 3 — accessibility conformance (receives spec from Step 2)
Spec: {Step 2 output}
Task: Validate the spec for WCAG 2.2 AA compliance before engineering handoff.
Flag any risks that require spec revision before implementation begins.
```

**Coordinator role:** Pass outputs between steps; do not modify Step 1 output before
feeding Step 2. If Step 3 flags critical issues, loop back to Step 2 (max 1 revision loop).

**Exit criteria:** ADR produced → spec produced → conformance check passed or revision loop complete.

---

## Pattern 3 — Token Cascade

**When to use:** A new theme, rebrand, or design system update requires token schema
changes that must be validated for brand alignment and component-state coverage before
engineering implementation.

**Trigger conditions:**
- User says "new theme", "rebrand tokens", "dark mode launch", or "token architecture"
- Output must be consumable by engineering (CSS variables, JSON, or style-dictionary config)

**Composition:**

```
Step 1: @design-system-architect  [design-tokens + color-system + theming skills]
         ↓ token schema draft
Step 2: @brand-steward            [brand-identity + brand-voice-tone skills] (parallel-review)
Step 2: @ux-designer              [ui-states-interaction skill]              (parallel-review)
         ↓ both reviews complete
Step 3: @design-system-architect  [css-mapping skill] — synthesize final token output
```

**Prompt templates:**

```text
# Step 1 — Token schema
Task: Design a complete token schema for {theme name}. Include:
- Primitive layer (raw color/scale values)
- Semantic layer (surface, text, border, interactive roles)
- Component layer (button, input, card, nav)
Use the existing token naming convention from sheen-20-tokens-naming.instructions.md.
Output: JSON token schema + semantic alias mapping table.

# Step 2a — Brand validation (parallel with 2b)
Input: {Step 1 JSON schema}
Task: Validate the semantic and primitive colors against {brand name} brand guidelines.
Flag any palette deviations. Return: pass/flag/fail per token group.

# Step 2b — Component state coverage (parallel with 2a)
Input: {Step 1 JSON schema}
Task: Validate that all interactive component states (default, hover, focus, active,
disabled, error) have semantic token assignments. Flag missing mappings.

# Step 3 — CSS mapping synthesis
Input: {Step 1 schema + Step 2a/2b reviews}
Task: Apply brand and state-coverage review feedback. Produce final CSS custom property
output (--sheen-* namespace) ready for engineering handoff.
```

**Exit criteria:** Brand review passed OR deviations documented as intentional decisions;
all interactive states covered; final CSS output produced.

---

## Authoring New Patterns

When a new multi-pillar composition pattern emerges from practice:

1. Name it (verb-noun: "parallel audit", "token cascade").
2. Define trigger conditions in plain language.
3. Draw the composition graph (coordinator → sub-agents, parallel vs. serial).
4. Write prompt templates for each sub-agent role.
5. Define merge/handoff instructions for the coordinator.
6. Define exit criteria.
7. Add the pattern here and register the factory in `checks.json` if it has a CI gate.
