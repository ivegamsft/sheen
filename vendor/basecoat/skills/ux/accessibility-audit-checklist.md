# Accessibility Audit Checklist — WCAG 2.1 AA

Use this checklist to audit a design or implementation against WCAG 2.1 Level AA. For each criterion, mark Pass, Fail, or N/A and document findings.

---

## Audit Overview

| Field | Value |
|---|---|
| **Feature / Screen** | `<what is being audited>` |
| **Auditor** | `<name or agent>` |
| **Date** | `YYYY-MM-DD` |
| **Tools Used** | `<e.g., axe, Lighthouse, NVDA, VoiceOver, manual inspection>` |
| **Overall Result** | Pass / Fail — `<summary>` |

---

## 1. Perceivable

Content must be presentable to users in ways they can perceive.

### 1.1 Text Alternatives

| # | Criterion | Status | Notes |
|---|---|---|---|
| 1.1.1 | All non-decorative images have meaningful alt text | Pass / Fail / N/A | |
| 1.1.1 | Decorative images use `alt=""` or `role="presentation"` | Pass / Fail / N/A | |
| 1.1.1 | Complex images (charts, diagrams) have extended descriptions | Pass / Fail / N/A | |
| 1.1.1 | Icon-only buttons have accessible labels (`aria-label` or visually hidden text) | Pass / Fail / N/A | |

### 1.2 Time-Based Media

| # | Criterion | Status | Notes |
|---|---|---|---|
| 1.2.1 | Pre-recorded audio has a text transcript | Pass / Fail / N/A | |
| 1.2.2 | Pre-recorded video has synchronized captions | Pass / Fail / N/A | |
| 1.2.3 | Pre-recorded video has audio description or text alternative | Pass / Fail / N/A | |
| 1.2.5 | Pre-recorded video has audio description (AA) | Pass / Fail / N/A | |

### 1.3 Adaptable

| # | Criterion | Status | Notes |
|---|---|---|---|
| 1.3.1 | Information and structure conveyed visually are also in markup (headings, lists, tables, landmarks) | Pass / Fail / N/A | |
| 1.3.2 | Reading order in the DOM matches the visual presentation order | Pass / Fail / N/A | |
| 1.3.3 | Instructions do not rely solely on sensory characteristics (shape, size, color, location) | Pass / Fail / N/A | |
| 1.3.4 | Content does not restrict display orientation (portrait/landscape) unless essential | Pass / Fail / N/A | |
| 1.3.5 | Form inputs have programmatically determinable purpose (`autocomplete` attributes) | Pass / Fail / N/A | |

### 1.4 Distinguishable

| # | Criterion | Status | Notes |
|---|---|---|---|
| 1.4.1 | Color is not the only visual means of conveying information | Pass / Fail / N/A | |
| 1.4.2 | Audio that plays automatically can be paused, stopped, or volume-controlled | Pass / Fail / N/A | |
| 1.4.3 | Text contrast ratio >= 4.5:1 (normal text) and >= 3:1 (large text >= 18pt or bold >= 14pt) | Pass / Fail / N/A | |
| 1.4.4 | Text can be resized up to 200% without loss of content or function | Pass / Fail / N/A | |
| 1.4.5 | Text is used instead of images of text (unless essential) | Pass / Fail / N/A | |
| 1.4.10 | Content reflows at 320px width without horizontal scrolling | Pass / Fail / N/A | |
| 1.4.11 | Non-text UI components and graphical objects have contrast ratio >= 3:1 | Pass / Fail / N/A | |
| 1.4.12 | Text spacing can be overridden (line height, letter spacing, word spacing, paragraph spacing) without breaking | Pass / Fail / N/A | |
| 1.4.13 | Hover/focus-triggered content is dismissible, hoverable, and persistent | Pass / Fail / N/A | |

---

## 2. Operable

UI components and navigation must be operable.

### 2.1 Keyboard Accessible

| # | Criterion | Status | Notes |
|---|---|---|---|
| 2.1.1 | All functionality is available via keyboard | Pass / Fail / N/A | |
| 2.1.2 | No keyboard traps — focus can always move away from any component | Pass / Fail / N/A | |
| 2.1.4 | Single-character keyboard shortcuts can be turned off or remapped | Pass / Fail / N/A | |

### 2.2 Enough Time

| # | Criterion | Status | Notes |
|---|---|---|---|
| 2.2.1 | Time limits can be turned off, adjusted, or extended | Pass / Fail / N/A | |
| 2.2.2 | Auto-updating content can be paused, stopped, or hidden | Pass / Fail / N/A | |

### 2.3 Seizures and Physical Reactions

| # | Criterion | Status | Notes |
|---|---|---|---|
| 2.3.1 | No content flashes more than 3 times per second | Pass / Fail / N/A | |

### 2.4 Navigable

| # | Criterion | Status | Notes |
|---|---|---|---|
| 2.4.1 | Skip navigation link is provided | Pass / Fail / N/A | |
| 2.4.2 | Pages have descriptive titles | Pass / Fail / N/A | |
| 2.4.3 | Focus order matches logical reading order | Pass / Fail / N/A | |
| 2.4.4 | Link purpose is clear from link text alone (or link + context) | Pass / Fail / N/A | |
| 2.4.5 | Multiple ways to reach each page (nav, search, sitemap) | Pass / Fail / N/A | |
| 2.4.6 | Headings and labels describe topic or purpose | Pass / Fail / N/A | |
| 2.4.7 | Focus indicator is visible on all interactive elements | Pass / Fail / N/A | |

### 2.5 Input Modalities

| # | Criterion | Status | Notes |
|---|---|---|---|
| 2.5.1 | Multi-point or path-based gestures have single-pointer alternatives | Pass / Fail / N/A | |
| 2.5.2 | Pointer events can be cancelled (down event does not trigger action alone) | Pass / Fail / N/A | |
| 2.5.3 | Visible labels match accessible names | Pass / Fail / N/A | |
| 2.5.4 | Motion-triggered actions have UI alternatives and can be disabled | Pass / Fail / N/A | |

---

## 3. Understandable

Information and UI operation must be understandable.

### 3.1 Readable

| # | Criterion | Status | Notes |
|---|---|---|---|
| 3.1.1 | Page language is identified in the `lang` attribute | Pass / Fail / N/A | |
| 3.1.2 | Language changes within the page are marked with `lang` attribute | Pass / Fail / N/A | |

### 3.2 Predictable

| # | Criterion | Status | Notes |
|---|---|---|---|
| 3.2.1 | Receiving focus does not trigger a context change | Pass / Fail / N/A | |
| 3.2.2 | Changing a setting does not trigger an unexpected context change | Pass / Fail / N/A | |
| 3.2.3 | Navigation is consistent across pages | Pass / Fail / N/A | |
| 3.2.4 | Components with the same function are identified consistently | Pass / Fail / N/A | |

### 3.3 Input Assistance

| # | Criterion | Status | Notes |
|---|---|---|---|
| 3.3.1 | Input errors are identified and described in text | Pass / Fail / N/A | |
| 3.3.2 | Labels or instructions are provided for user input | Pass / Fail / N/A | |
| 3.3.3 | Error messages suggest corrections when known | Pass / Fail / N/A | |
| 3.3.4 | Legal/financial/data submissions are reversible, verified, or confirmed | Pass / Fail / N/A | |

---

## 4. Robust

Content must be robust enough to be interpreted by assistive technologies.

### 4.1 Compatible

| # | Criterion | Status | Notes |
|---|---|---|---|
| 4.1.1 | HTML is valid — no duplicate IDs, proper nesting, complete start/end tags | Pass / Fail / N/A | |
| 4.1.2 | All UI components have accessible name, role, and value programmatically set | Pass / Fail / N/A | |
| 4.1.3 | Status messages are announced to assistive technology without receiving focus | Pass / Fail / N/A | |

---

## Findings Summary

| # | Criterion | Severity | Component/Location | Description | Recommended Fix |
|---|---|---|---|---|---|
| 1 | `<WCAG #>` | Critical / Major / Minor | `<component or page>` | `<what is wrong>` | `<how to fix>` |
| 2 | `<WCAG #>` | Critical / Major / Minor | `<component or page>` | `<what is wrong>` | `<how to fix>` |

---

## Severity Definitions

| Severity | Definition | Action |
|---|---|---|
| **Critical** | Blocks access for an entire user group (e.g., screen reader users cannot complete the task) | Must fix before release |
| **Major** | Significant difficulty for users with disabilities but a workaround exists | Fix in current sprint |
| **Minor** | Inconvenience that does not block task completion | Fix within next 2 sprints |
