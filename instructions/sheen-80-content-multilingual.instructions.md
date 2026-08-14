---
name: sheen-80-content-multilingual
compatibility: [github-copilot-cli]
description: "Always-on microcopy, plain language, i18n/l10n, and content design rules."
applyTo: "**/*"
metadata:
  band: 80
  layer: content
---

# Content Design and Multilingual Support

Apply these rules when writing, reviewing, or auditing any user-facing copy, error
messages, labels, or multilingual implementation. They implement ISO 24495-1 (plain
language), W3C i18n, BCP 47, and Unicode CLDR/ICU.

## Plain language (ISO 24495-1)

Plain language means the audience can find, understand, and use the content. Apply:

- **Reader-centred:** write for the user's task, not the system's perspective.
  "Save your changes" not "Mutation operation completed."
- **Findable:** the most important information comes first. Use headings, lists, and
  short paragraphs to let users scan before reading.
- **Understandable:** use common words. Define technical terms when they are
  unavoidable. Avoid jargon, acronyms without expansion, and ambiguous pronouns.
- **Usable:** instructions are in the order the user performs them. One idea per
  sentence. Active voice. Imperative for instructions ("Click Save").
- **Sentence length:** aim for 15-20 words. Maximum 30 words for complex legal or
  technical copy.

## Microcopy standards

- **Labels:** nouns or noun phrases; sentence case; no trailing colon in adjacent
  label/field layouts.
- **Placeholder text:** a usage example, not a repeat of the label ("e.g.
  name@company.com", not "Enter email"). Placeholder is not a substitute for a
  visible label.
- **Button text:** verb + optional noun ("Save changes", "Delete account"). Never
  "OK", "Submit", or "Click here" without context.
- **Tooltip text:** one sentence maximum. Explains, does not repeat, the label.
- **Empty states:** explain what the space is for and provide one actionable step
  ("No files yet. Upload your first file to get started.").
- **Success messages:** brief and specific ("Password updated"). Not "Operation
  successful."
- **Error messages:** name the problem and provide a path to resolution. Never blame
  the user. Never expose system internals. ("Email address is already in use. Sign
  in or use a different address.")
- **Loading states:** set expectation when duration is unknown ("Loading your
  files..."). Provide progress when measurable.
- **Destructive confirmations:** name exactly what will be deleted or lost. Never use
  generic "Are you sure?" without context.

## Internationalization (i18n) requirements

- All user-visible strings must be **externalized** -- not hardcoded. Use the
  consumer product's i18n framework (i18next, react-intl/FormatJS, gettext, ICU,
  Vue-i18n, or equivalent).
- Locale tags use **BCP 47** format (`en-US`, `fr-FR`, `zh-Hant-TW`).
- Never concatenate translated strings (word order differs by language). Use
  **ICU message format** with named placeholders (`{count} items found`, not
  `items found: ` + count).
- Use **CLDR/ICU** for: plural rules (`one`/`other`/`few`/`many`/`zero`),
  number formatting, currency, date/time, and ordinals. Never hardcode these.
- **Right-to-left (RTL):** all layouts and components must support RTL direction.
  Use logical CSS properties (`margin-inline-start`, not `margin-left`).
- **Text expansion:** translated strings can be 30-100% longer than English.
  UI containers must not clip or overflow on expansion. Test with pseudo-locale.
- **Date and time:** always store UTC; display in the user's local time zone via
  the `Intl.DateTimeFormat` API or equivalent. Never hardcode format strings.
- **Character encoding:** UTF-8 everywhere. Do not assume ASCII.

## Localization (l10n) quality

- Provide context notes for translators (what UI element the string appears in, any
  character limits, tone guidance).
- Flag strings that contain idiomatic expressions and provide a literal alternative.
- Screen all copy for untranslatable idioms before translation begins.

## Review lens

Before finalizing any copy or i18n implementation, ask:

- Is the language plain, reader-centred, and in the user's task frame?
- Are all user-visible strings externalized and not hardcoded?
- Do plurals use ICU plural rules (not hardcoded "s" suffixes)?
- Are date, time, number, and currency formatted via CLDR, not hardcoded?
- Is RTL supported via logical CSS properties?
- Will UI containers accommodate 30-100% string expansion?
- Do error messages name the problem and a fix, without blaming the user or
  exposing system internals?
