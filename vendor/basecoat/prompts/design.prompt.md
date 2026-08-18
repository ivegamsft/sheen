---
description: "Route a design request through the sheen framework, anchored to this product's PRODUCT.md context (design principles, brand, tokens, accessibility floor). Prefix any design request with 'design:' to get a PRODUCT.md-grounded response. Works in Copilot CLI, VS Code Copilot Chat, and any editor with Copilot Chat support."
model: claude-sonnet-4.6
tools: ["codebase", "changes"]
---

# design:

**How to invoke:**

```text
design: <your design request>
```

**Examples:**

```text
design: dark mode token schema for our button component
design: navigation pattern for a three-level product hierarchy
design: typography scale using our existing brand fonts
design: what accessibility requirements apply to our modal dialog?
design: brand voice for our error messages
```

---

## What This Prompt Does

Anchors every design request to the product's own `PRODUCT.md` — loading the
product's design principles, brand personality, accessibility floor, and
boundaries before routing to the right sheen agent. The result is design output
that is grounded in *this* product's context, not a generic best-practice answer.

---

## Workflow

### Step 1 — Load product context

Read `PRODUCT.md` from the repository root. Extract:

- **Design Principles** — the numbered strategic rules (used to evaluate options)
- **Brand Personality / Tone** — voice and never-do constraints (applied to all prose output)
- **Accessibility & Inclusion** — the floor (WCAG level, high-contrast requirement)
- **Boundaries** — what this product is not (used to redirect out-of-scope requests)
- **Anti-references** — what the output must never resemble

If `PRODUCT.md` is not present in the repo root, note its absence and proceed
with the sheen framework defaults. Recommend creating one:
```text
There is no PRODUCT.md in this repo. Responses will use sheen defaults.
Run: design: create PRODUCT.md for this product
```

### Step 2 — Route to the right pillar

Map the request to a sheen pillar using the keyword routing table:

| If the request is about… | Route to |
|---|---|
| Tokens, semantic aliases, CSS variables, themes | `@design-system-architect` |
| Color, palette, dark mode, contrast | `@design-system-architect` + `@accessibility-auditor` |
| Typography, font scales, type-ramp | `@design-system-architect` |
| Brand identity, logo, imagery, illustration | `@brand-steward` |
| Voice, tone, microcopy, error text | `@brand-steward` |
| Wireframes, layouts, navigation, responsive | `@ux-designer` |
| Interaction states, focus, hover, active | `@ux-designer` + `@accessibility-auditor` |
| WCAG, contrast ratios, ARIA, keyboard nav | `@accessibility-auditor` |
| Information architecture, taxonomy, sitemap | `@information-architect` |
| Component critique, craft review, audit | `@design-reviewer` |
| Creating `PRODUCT.md` | All pillars (use the structure from `https://product.md/`) |

### Step 3 — Generate grounded output

Produce the response with these constraints applied from `PRODUCT.md`:

1. **Apply design principles as evaluation criteria.** For any recommendation,
   explicitly note which principle(s) it satisfies or tensions with.

2. **Apply brand personality to all prose.** Follow the Tone section: craft-forward,
   calm, precise. Never use tutorial-tone, filler, or hedging.

3. **Apply accessibility floor.** Any output touching color, contrast, interaction,
   or focus must meet WCAG 2.2 AA as a minimum. State the conformance level.

4. **Apply boundaries.** If the request is out of scope (e.g., asking for a UI
   component implementation), redirect to the appropriate tool:
   ```
   Out of scope for sheen: [reason].
   For [request], use [recommended tool/approach].
   ```

5. **Apply anti-references.** If output would resemble an anti-reference pattern
   (e.g., a drop-in Material Design component spec), flag it and reframe.

### Step 4 — Output format

Structure output according to the request type:

**Token spec:**
```json
{
  "$type": "color",
  "$value": "#0969da",
  "$description": "Primary action color. WCAG AA on white (#ffffff) ✅ 4.7:1"
}
```

**Design decision:**
```
Decision: [what was decided]
Principle satisfied: [1, 3, 5]
Accessibility: WCAG 2.2 AA [✅ pass / ❌ fail — fix: ...]
Rationale: [one paragraph]
Next step: [concrete action]
```

**Component spec:**
```
Component: [name]
States: default, hover, focus, active, disabled
Token bindings: [semantic-token → component-token]
ARIA: [role, label pattern]
Keyboard: [interaction model]
```

**Architectural guidance:**
A numbered, reasoned recommendation with explicit principle references.

---

## Creating a PRODUCT.md

If the request is `design: create PRODUCT.md for this product`, run the
following discovery and generation workflow:

1. **Discover** — read `README.md`, `SPEC.md`, and any existing docs to extract:
   - What the product is and what it does
   - Who uses it
   - The team's stated design values or principles
   - Any existing brand guidelines or accessibility commitments

2. **Generate** — produce a conformant `PRODUCT.md` following the
   [product.md spec](https://product.md/):
   - One H1: the product name
   - All canonical sections present (Register, Users, Problem, Product Purpose,
     Brand Personality / Tone, Anti-references, Design Principles,
     Accessibility & Inclusion, Offer, Boundaries, Stack)
   - Machine islands for pricing and stack in spec-qualified fenced blocks
   - MDXLD frontmatter (`$type: Product`)

3. **Review** — ask the user to confirm before writing the file.

---

## Tips

- Always read `PRODUCT.md` before generating output — it is the single source
  of truth for design constraints in this repo.
- If `PRODUCT.md` design principles conflict with a request, name the tension
  explicitly and let the user decide.
- For requests touching multiple pillars, sequence the agents: tokens first,
  then brand, then a11y validation.
- The `debate:` prompt is the right choice when the user needs to compare
  options rather than implement a specific design direction.
