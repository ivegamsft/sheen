# Spec 07 — Skill Catalog

> Per-skill specification for every skill in root SPEC §8. Each entry is the
> authoring brief a `create-design-skill` run must satisfy (see spec 02 for the
> file contract). Format per skill:
>
> **`name`** *(pillar · maturity target)* — one-line purpose.
> · **Use for:** primary triggers · **Not for:** anti-triggers
> · **Workflow:** the core steps · **Output:** artifact(s) · **Pairs:** delegates/agents.

---

## Foundations

**`design-tokens`** *(foundations · stable)* — define and edit the DTCG token
source of truth.
· Use for: create/modify core & semantic tokens, add a token, restructure tiers ·
Not for: choosing a palette (`color-system`), auditing a repo (`design-audit`)
· Workflow: locate tier → add/edit `$type`/`$value`/`$description` → wire alias →
run `validate-tokens`. · Output: updated `tokens/**`. · Pairs: `theming`,
`color-system`; agent `design-system-architect`.

**`color-system`** *(foundations · stable)* — build accessible color ramps and
semantic color roles.
· Use for: generate palette, define brand hues, map colors to roles · Not for:
per-pair contrast check (`color-contrast-check`)
· Workflow: define core ramps → assign semantic roles → verify contrast across
themes. · Output: `tokens/core/color`, `tokens/semantic` color roles. · Pairs:
`color-contrast-check`, `theming`.

**`typography`** *(foundations · stable)* — define type families, scale, and text
roles.
· Use for: type ramp, font pairing, line-height/tracking, text roles · Not for:
inventorying existing fonts (`font-mapping`)
· Workflow: pick families → build size/weight ramp → map to text roles → check
legibility. · Output: `tokens/core/type` + semantic text roles. · Pairs:
`font-mapping`, `content-hierarchy`.

**`layout-grid-spacing`** *(foundations · stable)* — spacing scale, grid, and
breakpoints.
· Use for: define spacing scale, columns/gutters, breakpoints · Not for:
per-screen responsive behavior (`responsive-design`)
· Workflow: set spacing increments → define grid → set breakpoints. · Output:
`tokens/core/space` + grid tokens. · Pairs: `responsive-design`, `wireframing`.

**`iconography`** *(foundations · beta)* — icon system: grid, stroke, sizing,
naming.
· Use for: define icon spec, sizing tokens, naming rules · Not for: brand logo
(`logo-usage`)
· Workflow: set icon grid/stroke → size tokens → naming taxonomy. · Output: icon
guidelines + size tokens. · Pairs: `taxonomy`.

**`motion-elevation`** *(foundations · beta)* — motion (duration/easing),
elevation, and materials.
· Use for: define durations/curves, elevation levels, translucency materials ·
Not for: component-level state transitions (`ui-states-interaction`)
· Workflow: define duration/easing tokens → elevation shadows → material surfaces.
· Output: `tokens/core/motion|elevation|materials`. · Pairs: `theming`,
`component-spec`.

**`theming`** *(foundations · stable)* — build and validate light/dark/
high-contrast/brand themes.
· Use for: add a theme, override semantic tokens, ensure theme completeness · Not
for: creating new semantic keys (`design-tokens`)
· Workflow: clone semantic base → override values → run completeness + contrast
gates. · Output: `tokens/themes/**`. · Pairs: `color-system`,
`color-contrast-check`; agent `design-system-architect`.

---

## Brand

**`brand-identity`** *(brand · stable)* — codify the brand system (personality,
color, type, imagery, principles).
· Use for: define/refresh brand identity, write brand principles · Not for: voice
copy (`brand-voice-tone`)
· Workflow: articulate personality → map to visual foundations → document usage.
· Output: brand guidelines doc. · Pairs: `logo-usage`, `imagery-illustration`;
agent `brand-steward`.

**`brand-voice-tone`** *(brand · stable)* — define voice, tone, and messaging
principles.
· Use for: voice/tone guidelines, do/don't phrasing, tone matrix · Not for: UI
microcopy (`ux-writing`)
· Workflow: define voice attributes → tone-by-context matrix → examples. · Output:
voice & tone guide. · Pairs: `ux-writing`; agent `brand-steward`.

**`logo-usage`** *(brand · stable)* — logo variants, clear space, misuse rules.
· Use for: logo spec, safe area, sizing, do/don'ts · Not for: general iconography
(`iconography`)
· Workflow: define variants → clear space/min size → misuse examples. · Output:
logo usage sheet. · Pairs: `brand-identity`; agent `brand-steward`.

**`imagery-illustration`** *(brand · beta)* — photography and illustration
direction.
· Use for: image style, art direction, illustration system · Not for: icon grid
(`iconography`)
· Workflow: define style attributes → selection criteria → examples. · Output:
imagery guidelines. · Pairs: `brand-identity`; agent `brand-steward`.

---

## Information architecture

**`information-architecture`** *(ia · stable)* — structure content and define the
site/app map.
· Use for: content model, site map, card-sort synthesis · Not for: nav UI
patterns (`navigation-design`)
· Workflow: inventory content → group/label → produce site map. · Output: IA map +
content model. · Pairs: `navigation-design`, `taxonomy`; agent
`information-architect`.

**`wireframing`** *(ia · stable)* — low/mid-fidelity screen wireframes and layout
intent.
· Use for: wireframe a screen/flow, layout hierarchy, content blocks · Not for:
high-fidelity component specs (`component-spec`)
· Workflow: define screen goal → block layout → annotate states. · Output:
wireframe spec. · Pairs: `layout-grid-spacing`, `ui-states-interaction`; agent
`ux-designer`.

**`navigation-design`** *(ia · stable)* — navigation patterns and wayfinding.
· Use for: nav model (global/local/utility), breadcrumb/menu patterns · Not for:
content grouping (`information-architecture`)
· Workflow: choose nav model → define patterns → wayfinding rules. · Output: nav
spec. · Pairs: `information-architecture`; agent `information-architect`.

**`taxonomy`** *(ia · beta)* — controlled vocabularies and category schemes.
· Use for: build taxonomy, category labels, tag schema · Not for: entity
relationships (`ontology`)
· Workflow: gather terms → define hierarchy → governance rules. · Output: taxonomy
doc. · Pairs: `ontology`, `information-architecture`.

**`ontology`** *(ia · beta)* — entities, attributes, and relationships (semantic
model).
· Use for: model entities/relationships, define a semantic schema · Not for: flat
category lists (`taxonomy`)
· Workflow: identify entities → attributes → relationships → constraints. ·
Output: ontology model. · Pairs: `taxonomy`.

---

## Components / UI

**`component-spec`** *(components · stable)* — anatomy, variants, states, spacing,
a11y for one component, backed by a populated component inventory.
· Use for: spec a component, define variants/states, redlines · Not for:
whole-system audit (`design-system-audit`)
· Workflow: check `docs/components/inventory.md` for an existing spec →
anatomy → variants → states → spacing/tokens → a11y (ARIA role, states,
keyboard model per APG) → update inventory row. · Output: component spec
(inventory-backed). ·
Pairs: `ui-states-interaction`, `design-handoff`; agent `design-system-architect`.
· Standards: WAI-ARIA 1.2/APG (spec 08 §2.2).

**`ui-states-interaction`** *(components · stable)* — interaction and state
behavior (hover/pressed/focus/disabled/empty/error/loading).
· Use for: define state behavior, transitions, empty/error states · Not for:
static component anatomy (`component-spec`)
· Workflow: enumerate states → map to state tokens → transitions → safe error
states (no info leak). · Output: state spec. · Pairs: `component-spec`,
`motion-elevation`, `secure-ux`. · Standards: ISO 9241-110, OWASP error handling
(spec 08 §2.4, §2.11).

**`pattern-library`** *(components · stable)* — reusable UI patterns above the
component level, with a populated catalog of proven patterns.
· Use for: choose/document a pattern (modal, tabs, accordion, card, breadcrumb,
dropdown, tooltip, toast, stepper, data table, command palette, empty state) ·
Not for: a single component (`component-spec`)
· Workflow: match scenario to catalog entry → compose via `component-spec` +
`ui-states-interaction` → if no match, define new entry with intent/when-to-use/
anti-patterns → add to catalog to prevent drift. · Output: pattern entry
(catalog-backed). · Pairs: `component-spec`, `ui-states-interaction`,
`style-guide-authoring`.

**`design-system-audit`** *(components · stable)* — audit a design system's tokens
and components for coherence.
· Use for: check token/component consistency, find drift/duplication · Not for:
whole-repo product audit (`design-audit`)
· Workflow: inventory tokens/components → compare to contract → report gaps. ·
Output: audit report. · Pairs: `design-audit`, `design-tokens`.

---

## Web design & usability

**`web-usability-review`** *(usability · stable)* — evaluate a UI against NN/g +
HubSpot heuristics and ISO 9241 principles.
· Use for: heuristic evaluation, usability review of a page/flow · Not for:
automated a11y checks (`accessibility-audit`)
· Workflow: walk 10 NN/g heuristics + ISO 9241-110 dialogue principles → score on
ISO/IEC 25010 usability dimensions → severity-rate → recommend. · Output:
usability findings. · Pairs: `usability-mapping`; agents `ux-designer`,
`design-reviewer`. · Standards: ISO 9241-11/-110, ISO/IEC 25010 (spec 08 §2.4, §2.6).

**`landing-page-design`** *(usability · beta)* — structure and critique
high-converting landing pages.
· Use for: landing page structure, hero/CTA/hierarchy, conversion review · Not
for: full IA (`information-architecture`)
· Workflow: define goal → section structure → CTA/hierarchy → review. · Output:
landing page spec/review. · Pairs: `content-hierarchy`, `web-usability-review`.

**`responsive-design`** *(usability · stable)* — responsive/adaptive behavior
across breakpoints.
· Use for: define responsive behavior, breakpoint rules, reflow · Not for: the
spacing scale itself (`layout-grid-spacing`)
· Workflow: map layout per breakpoint → reflow/priority rules → test. · Output:
responsive spec. · Pairs: `layout-grid-spacing`.

**`content-hierarchy`** *(usability · beta)* — visual & information hierarchy of a
screen.
· Use for: prioritize content, scannability, hierarchy critique · Not for: copy
voice (`ux-writing`)
· Workflow: rank content → apply type/space hierarchy → verify scan path. ·
Output: hierarchy guidance. · Pairs: `typography`, `landing-page-design`.

---

## Content & localization

**`multilingual`** *(content · stable)* — i18n/l10n readiness and localization
design (W3C i18n, BCP 47, Unicode CLDR/ICU).
· Use for: i18n strategy, string externalization, RTL/pluralization/locale design ·
Not for: detecting an existing i18n framework (`i18n-framework-mapping`)
· Workflow: assess strings → externalize (BCP 47 tags) → ICU plural/format + RTL
rules → locale QA. · Output: i18n/l10n guidance. · Pairs: `i18n-framework-mapping`,
`ux-writing`. · Standards: W3C i18n, BCP 47, CLDR/ICU (spec 08 §2.9).

**`ux-writing`** *(content · beta)* — microcopy, labels, and error/content design
(NN/g + ISO 24495-1 plain language).
· Use for: button/label copy, error/empty-state text, content design · Not for:
brand voice system (`brand-voice-tone`)
· Workflow: apply voice → write in-context copy (plain-language principles) →
error/help guidance (no info leak). · Output: content/microcopy. · Pairs:
`brand-voice-tone`, `ui-states-interaction`, `secure-ux`. · Standards: ISO 24495-1
(spec 08 §2.7), OWASP safe-error copy (§2.11).

---

## Accessibility

**`accessibility-audit`** *(a11y · stable)* — WCAG 2.2 AA conformance audit
(+ WAI-ARIA/APG; maps to EN 301 549 / Section 508).
· Use for: WCAG audit, a11y issue triage, remediation plan, conformance statement ·
Not for: color contrast only (`color-contrast-check`)
· Workflow: run WCAG 2.2 AA checklist by principle → verify ARIA roles/keyboard per
APG → severity → remediation + conformance mapping. · Output: a11y audit report +
conformance statement. · Pairs: `color-contrast-check`, `usability-mapping`; agent
`accessibility-auditor`. · Standards: WCAG 2.2, WAI-ARIA 1.2/APG, EN 301 549,
Section 508, ISO/IEC 30071-1 (spec 08 §2.1–2.3).

**`color-contrast-check`** *(a11y · stable)* — verify contrast for token pairs and
themes against WCAG 2.2.
· Use for: check contrast ratios, validate theme pairs · Not for: full WCAG audit
(`accessibility-audit`)
· Workflow: resolve semantic pairs per theme → compute ratios vs. WCAG 2.2
(4.5:1 / 3:1; high-contrast stricter) → flag failures. · Output: contrast report. ·
Pairs: `theming`, `color-system`. · Standards: WCAG 2.2 (APCA forward-watch).

---

## Security & privacy UX

**`secure-ux`** *(security · beta)* — the user-facing design surface of OWASP +
privacy standards.
· Use for: safe error/empty states (no info leak), authentication & forgot-password
UX, input-validation feedback, clickjacking-safe affordances, consent & permission
patterns · Not for: engineering security review, pen-testing, or full ASVS
assessment (basecoat security assets)
· Workflow: identify security-sensitive surfaces → apply safe-error & auth-UX
patterns → design granular/revocable consent → verify no sensitive data in client
UI. · Output: secure-UX guidance + patterns. · Pairs: `ui-states-interaction`,
`ux-writing`, `accessibility-audit`; agent `design-reviewer`. · Standards: OWASP
ASVS/Top 10/Cheat Sheets, ISO/IEC 29184 (spec 08 §2.10–2.11).

---

## Mapping / discovery

**`css-mapping`** *(mapping · beta)* — inventory existing CSS and map to sheen
tokens.
· Use for: extract CSS vars/classes, detect Tailwind/Bootstrap/CSS-in-JS, propose
token mapping · Not for: authoring new tokens (`design-tokens`)
· Workflow: scan stylesheets → cluster values → propose token map. · Output:
mapping report + candidate tokens. · Pairs: `design-tokens`, `design-audit`.

**`font-mapping`** *(mapping · beta)* — inventory fonts and map to typography
tokens.
· Use for: list font families/weights/usage, map to type tokens · Not for:
defining the type ramp (`typography`)
· Workflow: scan usage → dedupe → map to type roles. · Output: font inventory +
mapping. · Pairs: `typography`, `design-audit`.

**`i18n-framework-mapping`** *(mapping · beta)* — detect and map multilingual
frameworks and locale coverage.
· Use for: identify i18next/react-intl/gettext/ICU/Vue-i18n, coverage gaps · Not
for: i18n design strategy (`multilingual`)
· Workflow: detect framework → inventory locales/keys → coverage report. ·
Output: i18n mapping. · Pairs: `multilingual`, `design-audit`.

**`usability-mapping`** *(mapping · beta)* — inventory flows/screens against
usability heuristics for coverage.
· Use for: map screens to heuristics, find review gaps · Not for: the heuristic
review itself (`web-usability-review`)
· Workflow: inventory flows → tag heuristic coverage → gap list. · Output:
coverage map. · Pairs: `web-usability-review`, `design-audit`.

---

## Lifecycle / operations

**`design-audit`** *(lifecycle · stable)* — repo/product-wide design assessment;
top-level entry point.
· Use for: audit an existing repo/product against sheen · Not for: token-only
audit (`design-system-audit`)
· Workflow: run mapping skills (css/font/i18n/usability) → run assessment skills
(system/a11y/usability) → synthesize scored report. · Output: consolidated audit +
prioritized backlog. · Pairs: all mapping + audit skills; agent `design-reviewer`.

**`design-bootstrap`** *(lifecycle · stable)* — start a design system from
scratch; top-level entry point.
· Use for: greenfield design system, initial tokens/brand/IA scaffold · Not for:
evolving an existing system (`design-update`)
· Workflow: capture brand/values → generate core+semantic tokens → seed themes →
starter components/IA. · Output: initial `tokens/**` + starter specs. · Pairs:
`design-tokens`, `theming`, `brand-identity`.

**`design-update`** *(lifecycle · beta)* — evolve/modernize an existing design
system.
· Use for: migrate/modernize tokens, refresh components, adopt new themes · Not
for: from-scratch (`design-bootstrap`)
· Workflow: audit current → plan migration → apply changes → verify no
regressions. · Output: migration plan + changes. · Pairs: `design-audit`,
`visual-regression`.

**`design-suggest`** *(lifecycle · beta)* — propose targeted, prioritized design
improvements.
· Use for: quick improvement suggestions, prioritized recommendations · Not for: a
full audit (`design-audit`)
· Workflow: sample artifact/repo → identify high-value fixes → prioritize. ·
Output: ranked suggestions. · Pairs: `design-review`.

**`design-debate`** *(lifecycle · beta)* — structured tradeoff analysis between
competing options.
· Use for: compare 2+ design options, decision record, tradeoff matrix · Not for:
critiquing one artifact (`design-review`)
· Workflow: frame options → criteria (appeal to design values) → tradeoff matrix →
recommendation. · Output: decision record. · Pairs: `craft-quality`; agent
`design-reviewer`.

**`design-exploration`** *(lifecycle · beta)* — generate and shape new design
concepts.
· Use for: ideate concepts, divergent directions, moodboard-to-direction · Not
for: evaluating options (`design-debate`)
· Workflow: gather intent → diverge concepts → converge to directions. · Output:
concept directions. · Pairs: `design-debate`, `brand-identity`.

**`design-handoff`** *(lifecycle · stable)* — package design for engineering.
· Use for: bundle tokens + component specs + redlines for devs · Not for: writing
the component spec (`component-spec`)
· Workflow: collect tokens/specs → produce redlines/annotations → export handoff
package. · Output: handoff package. · Pairs: `component-spec`, `design-tokens`.

---

## Governance / meta

**`style-guide-authoring`** *(governance · stable)* — produce a complete style
guide / pattern library.
· Use for: author a style guide, assemble guidelines into one doc · Not for: a
single component (`component-spec`)
· Workflow: gather foundations/components/patterns → structure guide → publish. ·
Output: style guide. · Pairs: `pattern-library`, `brand-identity`.

**`design-review`** *(governance · stable)* — craft-bar critique of a single
design artifact.
· Use for: review a screen/component/flow, critique against principles · Not for:
comparing options (`design-debate`)
· Workflow: assess vs. design values + heuristics → itemize issues → recommend. ·
Output: review notes. · Pairs: `craft-quality`; agent `design-reviewer`.

**`craft-quality`** *(governance · stable)* — apply the craft quality bar as an
actionable checklist.
· Use for: raise craft, polish pass, "is this high-craft?" check · Not for: full
usability audit (`web-usability-review`)
· Workflow: run craft checklist (detail, consistency, restraint) → flag → refine.
· Output: craft findings. · Pairs: `design-review`.

**`create-design-skill`** *(governance · stable)* — scaffold a new sheen skill
(meta).
· Use for: add a new SKILL.md, design triggers/frontmatter, scaffold folder · Not
for: writing an instruction (spec 04)
· Workflow: define one workflow → scaffold folder → write frontmatter/body →
`eval.yaml` → update catalog. · Output: new `skills/<name>/`. · Pairs: this spec
set.

**`user-research`** *(governance · beta)* — plan/synthesize research (personas,
interviews, usability testing).
· Use for: personas, interview guides, usability-test plans, synthesis · Not for:
heuristic review (`web-usability-review`)
· Workflow: define question → method → protocol → synthesize insights. · Output:
research artifacts. · Pairs: `information-architecture`, `web-usability-review`.

**`visual-regression`** *(governance · beta)* — design QA via snapshot/visual
diffing.
· Use for: set up/interpret visual regression, catch unintended UI change · Not
for: functional tests (out of scope)
· Workflow: baseline snapshots → diff on change → triage regressions. · Output: VR
setup + triage guidance. · Pairs: `design-update`, `design-system-audit`.
