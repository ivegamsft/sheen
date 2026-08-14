---
# [Product Name] Brand Guidelines

> Version: 0.1.0 | Owner: [Brand Team] | Last updated: [YYYY-MM-DD]
>
> These guidelines govern how [Product Name] is represented visually and verbally.
> When in doubt, ask the brand owner before deviating.

---

## 1. Brand foundation

**Mission:** [One sentence: what does [Product Name] do for its users?]

**Positioning:** [What makes [Product Name] distinct from alternatives?]

**Personality:** [Three to five adjectives that describe the brand's character.]

---

## 2. Voice and tone

**Voice (constant):** [2-3 sentences describing the brand's consistent character.]

**Tone by context:**

| Context | Tone | Example |
|---|---|---|
| Marketing | | |
| Onboarding | | |
| Error messages | | |
| Support | | |

**Writing rules:**
- Use sentence case for headings and UI labels (not Title Case).
- Prefer active voice.
- Define any technical terms before using them.
- Avoid filler words (just, very, really, quite).

---

## 3. Logo

| Variant | Usage | File |
|---|---|---|
| Primary (color) | Light backgrounds | `assets/logo-primary.svg` |
| Reversed (white) | Dark backgrounds | `assets/logo-reversed.svg` |
| Monochrome | Print, embossed | `assets/logo-mono.svg` |

**Logo rules:**
- Minimum size: [px or mm] to preserve legibility.
- Clear space: [describe] on all sides.
- Do not: recolor, rotate, distort, add effects, or use on busy backgrounds.
- Do not use the logo as a bullet point, pattern, or watermark.

---

## 4. Color palette

### Primary palette

| Name | Token | Hex (light) | Hex (dark) | Use |
|---|---|---|---|---|
| Primary | `color.primary` | | | Main brand actions, CTAs |
| Primary container | `color.primary-container` | | | Background for brand sections |
| On primary | `color.on-primary` | | | Text on primary |

### Neutral palette

| Name | Token | Hex (light) | Hex (dark) | Use |
|---|---|---|---|---|
| Surface | `color.surface` | | | Page and card backgrounds |
| On surface | `color.on-surface` | | | Body text |
| Outline | `color.outline` | | | Borders, dividers |

**Contrast compliance:** all text-on-background pairings must meet WCAG 2.2 AA
(4.5:1 text; 3:1 large text and non-text). Validate with `color-contrast-check`.

---

## 5. Typography

| Role | Family | Size | Weight | Line height | Token |
|---|---|---|---|---|---|
| Display | | | | | `typography.display` |
| Heading 1 | | | | | `typography.heading-1` |
| Heading 2 | | | | | `typography.heading-2` |
| Body | | | | | `typography.body` |
| Caption | | | | | `typography.caption` |
| Code | | | | | `typography.code` |

**Typography rules:**
- Use only licensed fonts listed above.
- Do not stretch, skew, or outline typefaces.
- Do not use decorative fonts for body text.
- Minimum body text: 16 px.

---

## 6. Imagery and illustration

**Photography style:** [Describe lighting, subject, mood, framing preferences.]

**Illustration style:** [Describe style (flat, line, isometric, etc.) and restrictions.]

**Rules:**
- Every non-decorative image needs meaningful alt text.
- Decorative images use `alt=""` and `aria-hidden="true"`.
- Images must represent diverse subjects, contexts, and abilities.
- Do not use stock imagery that misrepresents [Product Name]'s actual product or team.

---

## 7. Misuse examples

<!-- Add annotated "don't" examples with brief explanations. -->

---

## 8. Asset downloads

| Asset | Format | Link |
|---|---|---|
| Logo pack | SVG + PNG | |
| Color tokens | DTCG JSON | `tokens/` |
| Font files | WOFF2 | |
| Icon set | SVG | |

---

## 9. Questions and approvals

For deviations from these guidelines, open a request to [brand owner contact /
channel]. Include: the proposed deviation, the context, and why the standard
approach does not fit.
