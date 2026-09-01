---
name: sheen-90-standards-conformance
compatibility: [github-copilot-cli]
description: "Path-scoped conformance gates for design and UI surfaces: WCAG, ARIA, ISO 9241, DTCG, BCP 47, and OWASP."
applyTo: "**/*.html,**/*.css,**/*.scss,**/*.sass,**/*.less,**/*.styl,**/*.jsx,**/*.tsx,**/*.vue,**/*.svelte,**/*.astro,**/*.md,**/*.mdx,**/*.svg,**/components/**,**/ui/**,**/frontend/**,**/client/**,**/web/**,**/design/**,**/docs/**,**/tokens/**,**/assets/**,**/public/**,**/locales/**,**/i18n/**"
metadata:
  band: 90
  layer: standards
---

# Standards and Conformance

This instruction summarizes the cross-cutting conformance obligations that apply
to all sheen assets. It is the authoritative reference for what standards sheen
adopts, which checks are hard gates versus advisory, and where each standard is
enforced. Detailed requirements are in lower-band instructions; this file provides
the integrated compliance view.

See `specs/08-standards-conformance.spec.md` for the full normative catalog.

## Conformance summary

| Domain | Standard | Level / Target | Enforced by |
|---|---|---|---|
| Accessibility (content) | WCAG 2.2 | Level AA (mandatory); AAA (aspirational) | `checks.json` contrast gate; `accessibility-audit` skill |
| Accessibility (components) | WAI-ARIA 1.2 + APG | Full keyboard + role/state model | `checks.json` advisory; `sheen-30-components-states` |
| Accessibility (procurement) | EN 301 549, Section 508, ADA | Satisfied via WCAG 2.2 AA | `accessibility-audit` conformance statement |
| Accessibility (process) | ISO/IEC 30071-1 | HCD activity cycle | Skill workflow structure |
| Usability | ISO 9241-11 (definition), 9241-110 (dialogue) | Effectiveness + efficiency + satisfaction; seven dialogue principles | `web-usability-review`, `usability-mapping` |
| Human-centred design | ISO 9241-210 | HCD cycle | `user-research`, `design-bootstrap` |
| Product quality | ISO/IEC 25010 | Usability sub-characteristics as review dimensions | `design-review`, `design-audit` scorecards |
| Plain language | ISO 24495-1 | Reader-centred, findable, understandable, usable | `ux-writing`, `content-hierarchy`; `sheen-80-content-multilingual` |
| Design tokens | W3C DTCG | DTCG JSON format, alias syntax, resolvable references | `validate-tokens`; `checks.json` schema rule |
| Internationalization | W3C i18n + BCP 47 + Unicode CLDR/ICU | BCP 47 locale tags, ICU message format, logical CSS | `multilingual`, `i18n-framework-mapping`; `sheen-80-content-multilingual` |
| Privacy / consent UX | ISO/IEC 29184 | Clear, granular, revocable consent patterns | `secure-ux` skill |
| Security (UX surface) | OWASP ASVS (V2 auth UX), OWASP Top 10 | Safe error messages, auth UX, no client-side info leak | `secure-ux` skill; `checks.json` advisory |

## Hard gates vs. advisory checks

**Hard gates (`checks.json` error -- blocks release):**

- Color contrast below WCAG 2.2 AA thresholds (4.5:1 text, 3:1 non-text/focus)
- DTCG token schema violations (missing `$type`/`$value`, unresolvable alias, cycles)
- High-contrast theme missing a semantic token resolution
- `sheen-metadata.json` drift from the installed asset set

**Advisory checks (`checks.json` warn -- must be acknowledged, do not block):**

- Component spec missing ARIA role or keyboard model
- Error state spec without a "no-information-leak" note
- Missing `$description` on any token
- Catalog/frontmatter drift (skill name does not match folder)

## Non-negotiable design obligations

Regardless of consumer configuration, every sheen asset output MUST:

- Not recommend colors that fail WCAG 2.2 AA contrast.
- Not specify animations without a `prefers-reduced-motion` variant.
- Not produce error messages that expose system internals.
- Not produce component specs without ARIA role, state, and keyboard model.
- Not hardcode values that belong in the token system (colors, spacing, radius,
  motion timing, typography).
- Not write i18n-unsafe copy (hardcoded strings, concatenated translations, non-ICU
  plural handling).

## Scope boundary

sheen governs the **design and UX surface** of these standards. It does not replace:

- Engineering security review or penetration testing (basecoat's remit).
- Full ASVS assessment (engineering remit).
- Legal compliance determination (consumer's counsel).

When a sheen skill identifies a concern that crosses into engineering or legal
territory, it explicitly delegates or flags for human review.

## Maintenance

Standard versions are pinned in `specs/08-standards-conformance.spec.md`. Bumping
a version (e.g. WCAG 2.2 -> 3.0) is a spec change reviewed like any other, with a
CHANGELOG note and a potential major version bump if a `checks.json` threshold
changes.

## Review lens

Before shipping any sheen asset, ask:

- Does every color pair pass the WCAG 2.2 AA contrast gate?
- Are all tokens in DTCG format with resolvable aliases?
- Does every theme resolve every semantic token?
- Are all component specs ARIA-complete with keyboard model?
- Do all error messages avoid exposing system internals?
- Is all user-visible copy i18n-safe (externalized, ICU-plural-aware, RTL-safe)?
- Has the `sheen-metadata.json` been regenerated after any asset addition?
