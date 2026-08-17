# Prompt Guide — ♿ Accessibility

**Agent:** `@accessibility-auditor`  
**Pillar:** Accessibility  
**Invoke:** `/sheen a11y`, `/sheen wcag`, `/sheen contrast`, `/sheen keyboard`, `/sheen aria`, `/sheen conformance`, `/sheen usability-mapping`

The `accessibility-auditor` owns WCAG conformance, contrast validation, keyboard and
focus-order audits, ARIA labelling, and usability-risk triage.
It composes `accessibility-audit`, `color-contrast-check`, and `usability-mapping`.

---

## Agent-level prompts

### Pre-release accessibility gate

```
/sheen a11y
Run a pre-release accessibility review for our checkout flow (5 screens).
Coverage required: WCAG 2.2 AA. Check: color contrast, focus order,
keyboard traps, ARIA labels, form error announcements, and touch target sizes.
Return a severity-ranked findings table with: criterion ID, issue description,
affected element, severity (critical/major/minor), and remediation owner
(design or engineering).
```

**Flow:**
1. Define scope, WCAG level, and device targets.
2. Run `accessibility-audit` — full WCAG criterion sweep.
3. Run `color-contrast-check` — all text/background pairings.
4. Run `usability-mapping` — score accessibility risk per user segment.
5. Synthesize: de-duplicate, rank by severity × blast-radius, assign owners.

**Output shape:**
```
📋 Findings table
  ├── WCAG criterion | Issue | Element | Severity | Owner
  └── (sorted by severity)

🎨 Contrast matrix
  └── All pairings: ratio, AA pass/fail, AAA pass/fail

🔧 Remediation priorities
  ├── Critical (block launch): …
  ├── Major (fix in sprint): …
  └── Minor (backlog): …

📊 Usability risk by segment
  └── Score per user group (keyboard-only, screen reader, low vision, motor)
```

---

## Skill-by-skill reference

### `accessibility-audit` — WCAG conformance review

**Intent:** `audit-accessibility` / `keyboard-focus-audit` / `accessibility-conformance`  
**Keywords:** a11y, accessibility, wcag, aria, keyboard, focus-ring, tab-order, screen-reader, conformance, section-508

**When to use:** Any time a design or component needs WCAG validation before handoff
or release. Also use for Section 508 / EN 301 549 conformance requirements.

**Sample prompts:**

```
/sheen wcag
Run a WCAG 2.2 AA audit of our modal dialog component.
Check: focus trap, escape key dismiss, aria-modal, aria-labelledby,
background content aria-hidden, and return-focus on close.
Return pass/fail per criterion with remediation guidance.
```

```
/sheen keyboard
Audit keyboard accessibility for our main navigation menu.
Flows to check: open/close menu, navigate between top-level items,
open sub-menu, navigate sub-menu, close sub-menu and return focus.
Expected: all actions reachable without a mouse, visible focus indicator on all stops.
```

```
/sheen conformance
Produce a WCAG 2.2 AA conformance statement for our public-facing marketing site.
Format: VPAT-style table with criterion, level, status (supports/partial/does not support),
and remarks. Cover all Level A and AA criteria.
```

**Flow:**
1. Define scope (component, flow, or full product).
2. Map to applicable WCAG criteria (Level A and AA).
3. Per criterion: evaluate with evidence, return pass/partial/fail.
4. For fails: describe issue, affected element, remediation steps.

**Output:** WCAG criterion audit table · Keyboard navigation trace · Remediation list with criterion IDs

---

### `color-contrast-check` — Contrast ratio validation

**Intent:** `color-contrast-check`  
**Keywords:** contrast, color-contrast, luminance

**When to use:** Validating a color palette, checking specific text/background pairings,
or reviewing a new theme for WCAG contrast compliance.

**Sample prompts:**

```
/sheen contrast
Check all text/background pairings in our dark theme.
Token pairs to check: text-primary on surface-default, text-secondary on surface-default,
text-on-accent on interactive-default, text-disabled on surface-default.
Required: WCAG 2.2 AA (4.5:1 normal text, 3:1 large text). Flag failures with
suggested replacement values.
```

```
/sheen contrast
Our primary button is #0057B7 background with #FFFFFF text.
In hover state it lightens to #1A6EC9. Check both states at normal and large text sizes.
Also check the disabled state (#9DB8D9 background, #FFFFFF text).
Return: ratios, pass/fail per WCAG level, and corrected hex if failing.
```

**Flow:**
1. Compute luminance for each color pair using WCAG formula.
2. Calculate contrast ratio.
3. Evaluate against 4.5:1 (normal text AA), 3:1 (large text AA), 7:1 (AAA).
4. For fails: suggest adjusted values that preserve hue.

**Output:** Contrast ratio table (pair × ratio × AA × AAA) · Failure list · Suggested corrections

---

### `usability-mapping` — Accessibility risk by user segment

**Intent:** `usability-mapping`  
**Keywords:** usability-mapping, usability-score, heuristic-check

**When to use:** Prioritising accessibility work across multiple user segments, or
producing a risk register for accessibility QA planning.

**Sample prompts:**

```
/sheen usability-mapping
Map accessibility risk for our settings flow across four user segments:
keyboard-only, screen-reader (NVDA + JAWS), low-vision (200% zoom + high contrast),
and motor impairment (switch access). For each segment: identify the 3 highest-risk
interactions and score overall segment risk (1–5).
```

```
/sheen heuristic-check
Run a usability heuristic check specifically for screen-reader users on our
onboarding wizard. Score each step against: perceivable, operable, understandable,
robust (POUR). Return findings with priority (critical/major/minor).
```

**Flow:**
1. Define user segments and their assistive technology context.
2. Per segment: identify high-risk interactions.
3. Score overall risk per segment.
4. Cross-reference with WCAG criteria most relevant to each segment.

**Output:** Risk matrix (segment × interaction × severity) · POUR score per step · Priority remediation list
