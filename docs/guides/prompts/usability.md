# Prompt Guide — 📐 Usability

**Agent:** `@ux-designer`  
**Pillar:** Usability  
**Invoke:** `/sheen wireframe`, `/sheen layout`, `/sheen flow`, `/sheen navigation`, `/sheen responsive`, `/sheen ux-writing`, `/sheen interaction`, `/sheen spec`, `/sheen handoff`, `/sheen explore`

The `ux-designer` owns the usability mandate: flows, wireframes, interaction states,
responsive layouts, UX writing, component specs, and design handoff.
It composes `wireframing`, `ui-states-interaction`, `web-usability-review`, and `responsive-design`.

---

## Agent-level prompts

### End-to-end flow design

```
/sheen wireframe
Design an end-to-end onboarding flow for a SaaS project management tool.
Users: individual contributors and team leads. Entry point: post-signup.
Goals: connect first integration, invite teammates, create first project.
Produce: annotated lo-fi wireframes for each screen (text descriptions),
interaction notes, and edge cases (error, empty, loading states).
```

**Flow:**
1. Define user goal, entry point, exit criteria, and constraints.
2. Run `wireframing` — produce annotated lo-fi screen descriptions.
3. Run `ui-states-interaction` — document all states per interactive element.
4. Run `web-usability-review` — score against Effortless, Calm, Personal, Familiar, Complete.
5. Return: screen inventory, annotations, state matrix, usability score.

**Output shape:**
```
📐 Flow wireframes (text-described, annotated)
  ├── Screen 1: Welcome + context-setting
  ├── Screen 2: Integration connect
  ├── Screen 3: Team invite
  └── Screen 4: First project creation

🔄 State matrix
  └── Per interactive element: default / hover / focus / active / disabled / error / loading / empty

✅ Usability review
  └── Score per heuristic (Effortless, Calm, Personal, Familiar, Complete)

⚠️ Edge cases & open questions
```

---

## Skill-by-skill reference

### `wireframing` — Lo-fi flow wireframes

**Intent:** `wireframe-a-flow`  
**Keywords:** wireframe, lo-fi, sketch, flow-diagram

**When to use:** Early-stage flow design, rapid ideation, or when you need annotated
structure before visual design begins.

**Sample prompts:**

```
/sheen wireframe
Wireframe a checkout flow for a mobile e-commerce app.
Constraints: 3-step max, guest checkout option, Apple Pay + card.
Include: cart review, shipping, payment, confirmation.
Annotate each screen with: purpose, primary action, secondary action, error states.
```

```
/sheen lo-fi
Sketch a lo-fi dashboard for a data analytics tool.
Key modules: metric summary cards, trend chart, filter panel, table.
User: data analyst. Primary task: identify anomalies in the past 7 days.
```

**Flow:**
1. Define user goal, device context, constraints.
2. List screens / steps in the flow.
3. Describe each screen: layout regions, primary content, CTAs, nav.
4. Annotate interaction and edge cases.

**Output:** Screen inventory · Annotated descriptions per screen · Flow diagram (text) · Open questions

---

### `ui-states-interaction` — Interaction state specification

**Intent:** `ui-states-interaction`  
**Keywords:** interaction, state, hover, focus, active

**Sample prompt:**

```
/sheen interaction
Specify all interaction states for a multi-select filter chip component.
States required: default, hover, focus-visible, active (selected), disabled,
loading (async filter), error (fetch failed), empty (no options).
For each state: visual description, ARIA attribute changes, keyboard behaviour.
```

**Flow:**
1. Enumerate all required states for the component.
2. Per state: describe visual treatment, token mappings, ARIA changes, keyboard event.
3. Flag any missing states against the sheen-30-components-states standard.

**Output:** State matrix table · ARIA attribute changes per state · Keyboard event map · Token references

---

### `responsive-design` — Responsive layout and breakpoints

**Intent:** `responsive-layout`  
**Keywords:** responsive, mobile, breakpoint, viewport

**Sample prompt:**

```
/sheen responsive
Define a responsive strategy for a dashboard with: sidebar nav, metric cards
(4-up), a data table, and a detail panel. Breakpoints: 320, 768, 1024, 1440px.
For each breakpoint: layout description, nav behaviour (visible/collapsed/bottom),
card columns, table scroll strategy, panel stacking.
```

**Flow:**
1. Define breakpoint system (name, min-width, column count).
2. Per breakpoint: describe layout changes for each major region.
3. Define nav behaviour transitions.
4. Flag any content priority decisions (what hides vs. collapses vs. reflows).

**Output:** Breakpoint table · Layout descriptions per viewport · Navigation behaviour matrix · Content priority notes

---

### `layout-grid-spacing` — Grid and spacing system

**Intent:** `layout-grid-spacing`  
**Keywords:** layout, grid, spacing, density

**Sample prompt:**

```
/sheen layout
Define a layout grid and spacing scale for a data-dense enterprise product.
Grid: 12-column with 24px gutters on desktop, 4-column on mobile.
Spacing scale: 4px base unit, steps 0/2/4/8/12/16/24/32/48/64/96.
Density: default and compact modes. Output as token JSON.
```

**Flow:**
1. Define grid (columns, gutter, margin) per breakpoint.
2. Define spacing scale (base unit × multipliers).
3. Define density variants (default vs. compact token overrides).
4. Output token JSON + usage rules.

**Output:** Grid spec table · Spacing scale token JSON · Density override table · Usage rules

---

### `navigation-design` — Navigation architecture and patterns

**Intent:** `navigation-design`  
**Keywords:** navigation, nav, menu, wayfinding

**Sample prompt:**

```
/sheen navigation
Design a navigation system for a multi-product SaaS platform with 3 top-level
products, each with 4–8 sub-sections. Users switch between products frequently.
Constraints: sidebar must collapse to icon-only on tablet.
Output: nav hierarchy, wayfinding pattern choice with rationale, mobile adaptation.
```

**Flow:**
1. Map content hierarchy (products → sections → pages).
2. Select navigation pattern (sidebar, top nav, hybrid) with rationale.
3. Define collapse/expand behaviour and active state treatment.
4. Define mobile adaptation (bottom tab, hamburger, or side-drawer).

**Output:** Nav hierarchy diagram (text) · Pattern recommendation with rationale · State behaviour spec · Mobile adaptation

---

### `user-research` / `user-journey-mapping` — Journey and flow mapping

**Intent:** `user-journey-mapping`  
**Keywords:** user-journey, journey-map, flow, user-flow

**Sample prompt:**

```
/sheen flow
Map the user journey for a B2B contract manager: from "receive alert that
contract is expiring" to "renewal approved and filed". Stages: Awareness,
Review, Negotiation, Approval, Archive. For each stage: user actions,
system touchpoints, pain points, and improvement opportunities.
```

**Flow:**
1. Define persona, trigger event, and end state.
2. Break into stages.
3. Per stage: user actions, touchpoints, emotions/pain points, opportunities.
4. Identify the highest-friction moments and design interventions.

**Output:** Journey map table (stage × actions × touchpoints × pain × opportunity) · Friction hotspots · Prioritised opportunities

---

### `ux-writing` — UI copy and microcopy

**Intent:** `ux-writing`  
**Keywords:** ux-writing, label, cta, help-text, error-text

**Sample prompt:**

```
/sheen ux-writing
Write UX copy for a file upload component with these states:
- idle: drag-and-drop zone
- uploading: progress indicator
- success: file ready
- error: file too large (max 10MB)
- error: wrong format (PDF only)
Tone: clear and reassuring. Max 12 words per message.
```

```
/sheen label
Audit these 20 form field labels and helper text strings for clarity,
brevity (≤5 words per label), and tone alignment. Rewrite any that fail.
[strings here]
```

**Flow:**
1. Define tone constraints (max words, voice principles).
2. Per string/state: evaluate against clarity, brevity, tone.
3. Rewrite failing strings with rationale.

**Output:** String audit table · Rewritten strings · Tone notes per string

---

### `landing-page-design` — Landing page structure

**Intent:** `landing-page-design`  
**Keywords:** landing-page, hero, above-fold

**Sample prompt:**

```
/sheen landing-page
Design the information architecture and copy hierarchy for a developer tools
landing page. Goal: trial signups. Audience: backend engineers.
Include: hero (headline + sub + CTA), social proof, 3 core value props,
feature highlight, pricing signal, and footer CTA.
For each section: content purpose, recommended copy length, CTA label.
```

**Flow:**
1. Define conversion goal and audience.
2. Sequence sections by attention/trust arc.
3. Per section: content purpose, length, CTA, and persuasion principle.

**Output:** Page structure outline · Section briefs · Copy direction notes · CTA recommendations

---

### `web-usability-review` — Heuristic review

**Intent:** `web-usability-review`  
**Keywords:** usability, heuristic, web-usability

**Sample prompt:**

```
/sheen usability
Run a heuristic usability review of our account settings flow (5 screens).
Score each screen against: Effortless (minimal effort), Calm (low cognitive load),
Personal (contextualised), Familiar (expected patterns), Complete+Coherent (no gaps).
Return findings with severity and specific improvement actions.
```

**Flow:**
1. Define scope and score each screen against 5 heuristics (1–5 scale).
2. Identify lowest-scoring touchpoints.
3. Per finding: describe issue, severity (critical/major/minor), and fix.

**Output:** Heuristic score table (screen × heuristic) · Finding list by severity · Prioritised fix list

---

### `component-spec` — Component anatomy and specification

**Intent:** `component-spec`  
**Keywords:** component-spec, component-anatomy, spec

**Sample prompt:**

```
/sheen spec
Write a full component spec for a data table with: column sorting, row
selection (single + multi), inline editing, pagination, and empty/loading/error
states. Include: anatomy, token references, interaction spec, ARIA roles,
and keyboard navigation map.
```

**Flow:**
1. Define component anatomy (named parts).
2. Map each part to a design token.
3. Define all states per interactive element.
4. Write ARIA roles, labels, and keyboard navigation.

**Output:** Anatomy diagram (text) · Token mapping table · State spec · ARIA + keyboard reference

---

### `design-handoff` — Engineering handoff package

**Intent:** `design-handoff`  
**Keywords:** handoff, design-handoff, dev-handoff

**Sample prompt:**

```
/sheen handoff
Prepare an engineering handoff for the new notification centre component.
Include: design token references (not hex values), state spec, animation spec
(enter/exit motion), accessibility requirements, and known edge cases.
Flag anything the engineer needs to clarify with design before building.
```

**Flow:**
1. Replace any raw values with token references.
2. Document all interactive states.
3. Specify animation (duration token, easing, trigger).
4. List ARIA requirements and keyboard behaviour.
5. Flag open questions for design/engineering sync.

**Output:** Token reference table · State + animation spec · ARIA checklist · Open questions list

---

### `design-exploration` — Concept ideation

**Intent:** `design-exploration`  
**Keywords:** exploration, ideation, concepts

**Sample prompt:**

```
/sheen explore
Generate three distinct design concepts for a progress-tracking dashboard widget.
Concept A: minimal (data-forward, no decoration).
Concept B: contextual (benchmarks + trend indicators).
Concept C: motivational (goal proximity + celebration states).
For each: describe layout, key content, interaction, and tradeoff vs. the others.
```

**Flow:**
1. Define the design space and constraints.
2. Generate N concepts with distinct approaches (conservative, alternative, speculative).
3. Per concept: describe layout, content priority, interaction model, strengths, weaknesses.
4. Recommend a direction with rationale.

**Output:** N concept descriptions · Comparison matrix · Recommended direction with rationale
