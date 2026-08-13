# Spec 08 — Standards & Conformance

> Normative catalog of the external design, UX, accessibility, i18n, and security
> standards sheen adopts, and the assets that enforce or apply each. Implements
> root SPEC §2 and the "Standards & conformance" section. Where a standard defines
> a testable threshold, it becomes a `checks.json` rule (spec 05); where it defines
> process or principle, it becomes an instruction (spec 04) or skill workflow.

## 1. Conformance targets (summary)

| Domain | Baseline sheen conforms to | Aspirational |
|---|---|---|
| Accessibility (content) | **WCAG 2.2 Level AA** (W3C) | AAA where feasible; WCAG 3 / APCA (draft) forward-watch |
| Accessibility (components) | **WAI-ARIA 1.2** + **ARIA Authoring Practices Guide (APG)** | — |
| Accessibility (procurement/law) | **EN 301 549**, **Section 508**, ADA (all reference WCAG) | — |
| Accessibility (process) | **ISO/IEC 30071-1** | — |
| Usability (definition) | **ISO 9241-11** | — |
| Interaction principles | **ISO 9241-110** dialogue principles | — |
| Human-centred design process | **ISO 9241-210** | — |
| Product quality model | **ISO/IEC 25010** (usability characteristic) | — |
| Plain language / content | **ISO 24495-1** | — |
| Design tokens format | **W3C DTCG** | — |
| Internationalization | **W3C i18n**, **BCP 47** language tags, **Unicode CLDR/ICU** | — |
| Privacy/consent UX | **ISO/IEC 29184** (online privacy notices & consent) | — |
| Security (verification) | **OWASP ASVS** (UX-relevant controls) | — |
| Security (risk awareness) | **OWASP Top 10** + **OWASP Cheat Sheet Series** | — |

## 2. Standard → adopted content → enforcing assets

### 2.1 W3C — WCAG 2.2 (AA)
- **Adopt:** all AA success criteria; the four principles (Perceivable, Operable,
  Understandable, Robust); contrast minimums (4.5:1 text / 3:1 large & non-text).
- **Enforce:** `checks.json` token contrast rule (spec 01 §6 / 05 §2.1 rule 5);
  skills `accessibility-audit`, `color-contrast-check`; instruction
  `sheen-10-core-accessibility`.

### 2.2 W3C — WAI-ARIA 1.2 + ARIA APG
- **Adopt:** roles, states, properties, and keyboard interaction patterns per APG.
- **Enforce:** `component-spec` and `ui-states-interaction` MUST specify ARIA role,
  states, and keyboard model; advisory `checks.json` rule flags components missing
  an ARIA/keyboard section; instruction `sheen-30-components-states`.

### 2.3 EN 301 549 / Section 508 / ADA
- **Adopt:** conformance is satisfied via WCAG 2.2 AA (these standards reference
  WCAG). Document the mapping for procurement.
- **Enforce:** `accessibility-audit` produces a conformance statement referencing
  the applicable regime.

### 2.4 ISO 9241-11 (usability) & 9241-110 (interaction principles)
- **Adopt:** usability = effectiveness + efficiency + satisfaction in a context of
  use; the seven dialogue/interaction principles (suitability for the task,
  self-descriptiveness, conformity with expectations, learnability, controllability,
  error tolerance, user engagement).
- **Enforce:** `web-usability-review` and `usability-mapping` evaluate against these
  alongside the NN/g heuristics; instruction `sheen-40-web-usability`.

### 2.5 ISO 9241-210 (human-centred design)
- **Adopt:** the HCD activity cycle (understand context → specify requirements →
  produce designs → evaluate).
- **Enforce:** `user-research` structures its workflow on the HCD cycle;
  `design-bootstrap` / `design-update` sequence work accordingly.

### 2.6 ISO/IEC 25010 (product quality)
- **Adopt:** usability sub-characteristics (appropriateness recognizability,
  learnability, operability, user error protection, UI aesthetics, accessibility)
  as review dimensions.
- **Enforce:** `design-review`, `design-audit` scorecards use these dimensions.

### 2.7 ISO 24495-1 (plain language)
- **Adopt:** reader-centred, findable, understandable, usable content principles.
- **Enforce:** `ux-writing` and `content-hierarchy`; instruction
  `sheen-80-content-multilingual`.

### 2.8 W3C DTCG (design tokens)
- **Adopt:** the DTCG JSON format (`$type`/`$value`/`$description`, alias syntax).
- **Enforce:** spec 01 in full; `validate-tokens` schema rule.

### 2.9 W3C i18n + BCP 47 + Unicode CLDR/ICU
- **Adopt:** externalized strings, BCP 47 locale tags, CLDR/ICU message format,
  plural/gender/number/date formatting, bidi/RTL handling.
- **Enforce:** `multilingual`, `i18n-framework-mapping`; instruction
  `sheen-80-content-multilingual`.

### 2.10 ISO/IEC 29184 (privacy notices & consent)
- **Adopt:** clear, granular, revocable consent UX; layered notices.
- **Enforce:** `secure-ux` (consent & permission patterns); `ux-writing` for notice
  copy.

### 2.11 OWASP — ASVS, Top 10, Cheat Sheets
- **Adopt (UX-relevant only):** secure-by-default UI; safe error messages that do
  not leak (Error Handling Cheat Sheet); authentication & forgot-password UX (ASVS
  V2 / Authentication Cheat Sheet); input validation feedback UX; clickjacking
  defense affordances; no sensitive data in the client UI.
- **Enforce:** `secure-ux` skill; `ui-states-interaction` error/empty states MUST
  follow safe-error guidance; `ux-writing` error copy MUST NOT reveal system
  internals; advisory `checks.json` rule flags error-state specs lacking a
  "no-information-leak" note.

## 3. Scope boundary

sheen governs **design and UX conformance** to the above. It does **not** replace
engineering security review, penetration testing, or a full ASVS assessment — those
belong to basecoat's security assets. sheen's remit is the *user-facing design
surface* of these standards (secure UX, accessible UI, understandable content),
and it hands deeper security/verification work to basecoat.

## 4. Maintenance

- Standard versions are pinned here; bumping a version (e.g. WCAG 2.2 → 3.0) is a
  spec change reviewed like any other, with a CHANGELOG note and possible major
  version bump if it changes a `checks.json` threshold.
- New regimes a consumer must meet (e.g. a national accessibility law) are added to
  §1 with their WCAG mapping rather than duplicated criteria.
