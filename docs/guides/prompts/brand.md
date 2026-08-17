# Prompt Guide — 🖼️ Brand

**Agent:** `@brand-steward`  
**Pillar:** Brand  
**Invoke:** `/sheen brand`, `/sheen logo`, `/sheen voice`, `/sheen tone`, `/sheen imagery`, `/sheen icon`

The `brand-steward` owns brand integrity across the visual and verbal identity: logo usage,
imagery direction, illustration style, voice and tone, microcopy, and iconography.
It composes `brand-identity`, `brand-voice-tone`, `logo-usage`, and `imagery-illustration`.

---

## Agent-level prompts

### Full brand audit

```
/sheen brand
Run a full brand integrity audit for our SaaS product redesign.
Cover: logo usage compliance, imagery and illustration consistency,
voice and tone alignment with our "confident but approachable" brief,
and iconography coherence with the brand system.
Return findings by severity with remediation owners.
```

**Flow:**
1. Clarify brand brief, existing assets, and target audience.
2. Run `brand-identity` — audit visual identity elements against guidelines.
3. Run `logo-usage` — check clear space, misuse, and co-branding rules.
4. Run `imagery-illustration` — audit photography style and illustration palette.
5. Run `brand-voice-tone` — review microcopy samples against voice principles.
6. Synthesize: severity-ranked findings, owner assignments, next actions.

**Output shape:**
```
📋 Brand audit report
  ├── Logo compliance: PASS / WARN / FAIL per usage context
  ├── Imagery findings: N critical, N major, N minor
  ├── Voice alignment: scored against 4 voice principles
  └── Iconography: coverage gaps + style inconsistencies

🔧 Remediation plan
  ├── Critical (fix before launch): …
  ├── Major (fix in next sprint): …
  └── Minor (backlog): …
```

---

## Skill-by-skill reference

### `brand-identity` — Visual identity review

**Intent:** `brand-identity-review`  
**Keywords:** brand, brand-identity, visual-identity

**When to use:** Reviewing a design deliverable, product screen, or marketing asset for
brand alignment. Use before launch gates or when onboarding a new vendor.

**Sample prompts:**

```
/sheen brand
Review these three product screens for brand alignment.
Primary brand color: #0057B7. Typeface: Inter. Tone: direct and human.
Flag any off-brand color usage, font substitutions, or tone mismatches.
```

```
/sheen brand
We're onboarding a new design agency. Draft a brand compliance checklist
covering: color usage, typography, logo placement, imagery style, and
voice principles. Base it on our sheen brand guidelines.
```

**Flow:**
1. Ingest the asset or brief.
2. Check color usage against palette (exact match + perceptual proximity).
3. Check typography against type system.
4. Check tone against brand voice principles.
5. Return annotated findings with severity.

**Output:** Annotated findings list · Compliance checklist · Pass/fail summary per category

---

### `logo-usage` — Logo compliance

**Intent:** `logo-usage-review`  
**Keywords:** logo, logotype, mark, logo-usage

**Sample prompt:**

```
/sheen logo
Review our logo usage rules and flag violations in these six application
contexts: app icon, email header, co-branded partner page, white-label
variant, dark background, and print letterhead.
Specify minimum clear space, minimum size, and prohibited treatments for each.
```

**Flow:**
1. Define minimum clear space rule (based on x-height or bounding box).
2. Define minimum size per medium (screen px, print mm).
3. Enumerate prohibited treatments (outline-only, stretched, recolored).
4. Review each context against rules and return pass/fail with notes.

**Output:** Logo usage matrix (context × rule) · Violation list · Approved treatment examples

---

### `imagery-illustration` — Photography and illustration direction

**Intent:** `imagery-illustration`  
**Keywords:** imagery, illustration, photography

**Sample prompt:**

```
/sheen imagery
Define photography and illustration guidelines for a wellness app.
Photography: authentic, diverse, warm (avoid stock-photo aesthetic).
Illustration: flat, geometric, 2-color palette from brand primaries.
Output: style brief, do/don't examples (described), and selection criteria
for our creative team.
```

**Flow:**
1. Define photography mood, subject, composition, and treatment rules.
2. Define illustration style (stroke, fill, palette, level of detail).
3. Write selection criteria for commissioning and sourcing.
4. Produce a do/don't comparison brief.

**Output:** Photography style brief · Illustration style brief · Do/don't list · Selection criteria

---

### `brand-voice-tone` — Voice, tone, and microcopy

**Intent:** `brand-voice-tone`  
**Keywords:** voice, tone, microcopy, brand-voice

**Sample prompt:**

```
/sheen voice
Review these 12 UI strings (button labels, error messages, empty states,
onboarding copy) against our brand voice: clear, direct, empathetic, never
condescending. Rewrite any that miss the mark.
Strings: [paste strings here]
```

```
/sheen tone
Draft brand voice principles for a B2B developer tools company.
We want to sound: expert without being arrogant, friendly without being
informal, precise without being cold. Include 4 principles, a do/don't
pair for each, and 3 microcopy examples per principle.
```

**Flow:**
1. Define or ingest voice principles (4–6 named principles).
2. Score each string/sample against each principle (pass/revise/fail).
3. Rewrite failing strings with rationale.
4. Return: principles reference card + annotated string audit.

**Output:** Voice principles card · Microcopy audit table · Rewritten strings with change notes

---

### `iconography` — Icon system review

**Intent:** `iconography-review`  
**Keywords:** icon, iconography, pictogram

**Sample prompt:**

```
/sheen icon
Audit our icon set for system consistency. Check:
- Are all icons on the same grid (24×24px, 2px stroke)?
- Do we have all required categories (navigation, action, status, feedback)?
- Are any icons ambiguous (could be confused with another)?
Flag gaps and ambiguities with suggested alternatives.
```

```
/sheen icon
We're adding 8 new icons for a payments module (transfer, receive, schedule,
recurring, dispute, statement, limit, account). Define: grid spec, optical
sizing notes, metaphor rationale, and accessibility label for each.
```

**Flow:**
1. Audit existing icons against grid, stroke, and category coverage.
2. Flag inconsistencies and ambiguous metaphors.
3. For new icons: define metaphor, optical sizing, grid placement, label.
4. Return: audit findings + spec for new icons.

**Output:** Icon audit report · Coverage gap list · New icon spec sheet (name, metaphor, label, grid notes)
