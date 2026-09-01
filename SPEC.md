# basecoat-sheen — Repository Specification

> Status: **Draft v0.1** · Owner: TBD · Last updated: 2026-08-13
>
> This is a design specification and implementation contract for
> basecoat-sheen. It defines what the repository is, how it is structured, and
> the conventions every asset must follow so implementation stays aligned to a
> shared contract.
>
> **Detailed specs:** see [`specs/`](specs/README.md) — token system (01), skill
> contract (02), agent contract (03), instruction layers (04), validation (05),
> consumption/sync (06), and the per-skill catalog (07).

---

## 1. Purpose

**basecoat-sheen** is a governance repository of reusable AI customization assets
(skills, agents, instructions, prompts, templates) for **design, brand, and UI
craft**. It is the "finish coat" sibling to
[`basecoat`](https://github.com/ivegamsft/sheen/): where basecoat governs
the engineering SDLC, sheen governs how products *look, feel, read, and hold up to
a craft bar*.

It is consumed the same way basecoat is — synced into a target repository via a
config file and sync script — so a team can adopt engineering governance
(basecoat) and design governance (sheen) through one consistent mechanism.

### Non-goals

- Not a component library or CSS framework (it governs how you build one; it does
  not ship runtime UI code).
- Not a replacement for basecoat — it depends on and parallels it.
- Not a design tool integration (no Figma plugin in v1; interoperability is via
  file formats, e.g. DTCG tokens).

---

## 2. Design context & influences

The repository's craft bar and vocabulary are derived from these sources. Each maps
to a pillar and is captured durably under `references/` and distilled into
`docs/design-context.md` and `instructions/`.

| Source | What we take from it | Pillar |
|---|---|---|
| **impeccable** *(inspiration only)* | The quality/craft bar; "invisible when right" ethos | Craft |
| **brand.github.com** | Brand identity system: logo, color, type, voice, imagery | Brand |
| **Nielsen Norman Group (NN/g)** | The 10 usability heuristics + UX-research rigor; backbone of usability skills | Web usability |
| **HubSpot — 6 guidelines for exceptional website design & usability** | Practical web usability heuristics | Web usability |
| **Website style-guide examples / uistyleguide.com** | How to author and structure a style guide / pattern library | Style guide |
| **Material 3 (m3.material.io)** | Token-driven foundations, components, states, motion, theming | Design system |
| **Fluent 2 (fluent2.microsoft.design)** | Global + alias token model, high-contrast theming, state tokens, cross-platform parity | Design system |
| **Windows 11 design principles (learn.microsoft.com)** | Principled value set (Effortless · Calm · Personal · Familiar · Complete + Coherent) + signature experiences: materials/translucency, geometry, layering | Craft / design system |
| **Leading studios — Sapient, DesignRush "best modern websites", Seán Halpin** | Aesthetic bar: modern layout, motion, storytelling, positive space, distinctive type | Craft / aesthetic |

**Usability backbone:** NN/g's ten heuristics — visibility of system status, match to
the real world, user control & freedom, consistency & standards, error prevention,
recognition over recall, flexibility & efficiency, aesthetic & minimalist design,
help users recover from errors, help & documentation — are the evaluation checklist
for `web-usability-review`, `usability-mapping`, and the `accessibility-auditor` /
`design-reviewer` agents. The studio references seed `docs/design-context.md`'s
aesthetic direction and the `design-exploration` / `design-debate` skills.

**Design values:** `docs/design-context.md` and `sheen-10-core-design-principles`
adopt a named value set adapted from Windows 11 (Effortless, Calm, Personal,
Familiar, Complete + Coherent) and Material 3, so every skill can appeal to shared
principles
during `design-review` and `design-debate`.

**Standards & conformance:** the influences above set the aesthetic and craft bar;
the *conformance* bar is set by formal standards — W3C **WCAG 2.2 AA** &
**WAI-ARIA/APG**, **ISO 9241** (usability/HCD) & **ISO/IEC 25010**, **ISO 24495-1**
(plain language), **W3C DTCG** tokens, **BCP 47 / Unicode CLDR-ICU** for i18n, and
**OWASP** (ASVS/Top 10) for secure UX. These are catalogued, mapped to the assets
that enforce them, and turned into `checks.json` gates in
[`specs/08-standards-conformance.spec.md`](specs/08-standards-conformance.spec.md).

---

## 3. Relationship to basecoat

sheen deliberately mirrors basecoat so tooling and mental models transfer.

| Concern | basecoat | basecoat-sheen |
|---|---|---|
| Consumer config | `.basecoat.yml` | `.sheen.yml` |
| Layered instructions prefix | `basecoat-10-core-*` | `sheen-10-core-*` |
| Skill unit | `skills/<name>/SKILL.md` + `eval.yaml` | identical |
| Agent unit | `agents/*.agent.md` (+ `*.agent.eval.yaml`) | identical |
| Inventory | `basecoat-metadata.json` | `sheen-metadata.json` |
| Validation manifest | `checks.json` | `checks.json` (+ token schema checks) |
| Sync / rollback | `sync.*` / `rollback.*` | same, basecoat-compatible |
| Net-new | — | `tokens/` machine-readable design tokens |

**Decision:** sheen is a *standalone sibling repo*, not a fork. It shares
conventions and can be synced alongside basecoat, but owns its own catalog.

### 3.1 Vendored basecoat

basecoat is **vendored into this repo** at [`vendor/basecoat/`](vendor/basecoat/)
so sheen's design/UX finish coat ships on top of basecoat's engineering foundation
in one place. See [`vendor/basecoat/VENDOR.md`](vendor/basecoat/VENDOR.md) for
provenance (pinned commit `daf8364`, 2026-08-10) and the include/exclude list.

- The vendored tree is **read-only**; changes belong upstream. Refresh by
  re-cloning at a new commit and bumping the provenance note.
- Namespaces never collide: vendored assets stay `basecoat-*`, sheen assets are
  `sheen-*`. A consumer can sync both together.
- sheen assets live at the repo root (`skills/`, `agents/`, `instructions/`, …);
  vendored basecoat lives only under `vendor/`. Validation (spec 05) and
  `sheen-metadata.json` scan the root, not `vendor/`.

---

## 4. Asset model

Six primitive types. The first five follow basecoat definitions; the token set is
net-new to sheen:

1. **Skill** — a discoverable, self-contained workflow (`SKILL.md`) with trigger
   phrases in frontmatter, a short workflow body, guardrails, and optional
   `templates/`. Paired with an `eval.yaml` routing test. Target ≤ ~500 tokens.
2. **Agent** — a design-role persona (`*.agent.md`) that composes skills and
   instructions; paired with `*.agent.eval.yaml`.
3. **Instruction** — ambient guidance applied by path scope (`*.instructions.md`),
   layered by the numbering scheme in §7.
4. **Prompt** — a reusable one-shot design task (generate palette, run critique).
5. **Template** — starter artifacts consumed by skills (style guide, component
   spec, brand guidelines, design review).
6. **Token set** — machine-readable design tokens under `tokens/` (see §6),
   validated by `checks.json`. This is the source of truth that many skills read,
   write, or audit against.

---

## 5. Repository structure

```text
basecoat-sheen/
├── README.md · CONTRIBUTING.md · CHANGELOG.md · LICENSE
├── .lexicon.md                    # canonical design vocabulary
├── .sheen.yml.example             # consumer config (sync source, asset allow-lists)
├── version.json · sheen-metadata.json · checks.json
│
├── skills/                        # primary deliverable (flat folders; see §8)
│   ├── _catalog.md
│   └── <skill-name>/ { SKILL.md, eval.yaml, templates/ }
│
├── agents/                        # *.agent.md (+ *.agent.eval.yaml)
├── instructions/                  # sheen-<NN>-<layer>-<topic>.instructions.md (§7)
│                                   #   10 core · 20 tokens · 30 components · 40 web/usability
│                                   #   50 brand · 60 IA/navigation · 70 taxonomy/ontology · 80 content/i18n · 90 standards
├── prompts/
├── templates/                     # shared cross-skill templates
│   └── { style-guide/, component-spec/, brand-guidelines/, design-review/ }
│
├── tokens/                        # DTCG/W3C design tokens (§6)
│   ├── core/ { color, type, space, radius/shape, elevation, materials, motion }   # global primitives
│   ├── semantic/                  # alias role + state tokens (surface, on-surface, primary, hover…)
│   └── themes/ { light, dark, high-contrast, <brand> }
│
├── references/                    # curated notes from the influence sources (§2)
│
├── vendor/                        # vendored upstream (read-only)
│   └── basecoat/                  # pinned copy of basecoat assets + tooling (see VENDOR.md)
│
├── docs/                          # mkdocs site
│   ├── index.md · getting-started.md · philosophy.md · design-context.md
│   ├── foundations/ · brand/ · components/ · accessibility/ · usability/
│   ├── guides/                    # sheen-yml, authoring-a-skill, adopting-tokens
│   └── reference/                 # generated catalog
│
├── scripts/                       # validate-tokens, build-metadata, lint-frontmatter, contrast-check
├── sync.ps1 · sync.sh · rollback.ps1 · rollback.sh · mkdocs.yml
├── tests/                         # eval + schema harness
├── .github/                       # workflows: eval, token-lint, a11y-gate, docs-deploy
└── .githooks/ · .vscode/ · .copilot/ · .gitignore · .gitattributes · .markdownlint.json · .gitleaks.toml
```

---

## 6. Design-token system (`tokens/`)

**Decision (confirmed):** tokens are a first-class, validated system.

- **Format:** W3C Design Tokens Community Group (DTCG) JSON (`$type`, `$value`,
  `$description`), aligned with both Material 3 and Fluent 2 structure.
- **Three tiers** (the DTCG "global vs. alias" model shared by M3 and Fluent 2):
  - `core/` — raw **global** primitives (palette ramps, type scale, spacing scale,
    radii/shape (geometry), elevation levels, **materials** (translucency/backdrop,
    e.g. Mica/Acrylic-style surfaces), motion durations/easings). Context-agnostic.
  - `semantic/` — **alias** role tokens referencing core (e.g. `color.surface`,
    `color.on-surface`, `color.primary`), including **state tokens** for
    hover / pressed / selected / disabled / focus.
  - `themes/` — light / dark / **high-contrast** / per-brand overrides of semantic
    tokens.
- **Cross-platform output:** a build step (Style Dictionary or equivalent) transforms
  the DTCG source into CSS custom properties, JS/TS, and platform formats, so tokens
  stay single-source-of-truth across web and app surfaces (Fluent 2 parity goal).
- **Validation (`checks.json` + `scripts/validate-tokens`):**
  - schema conformance (valid DTCG, resolvable references, no cycles),
  - naming conventions match `.lexicon.md`,
  - accessibility gates (semantic color pairs meet WCAG 2.2 contrast; the
    high-contrast theme meets its stricter targets),
  - theme completeness (every semantic token resolves in every theme, including
    state and high-contrast).

Skills such as `design-tokens`, `color-system`, and `color-contrast-check` read
and write these files; `design-system-audit` audits a consumer against them.

---

## 7. Naming & layering conventions

- **Skills:** kebab-case folder; `name` in frontmatter equals folder name.
- **Instructions:** `sheen-<NN>-<layer>-<topic>.instructions.md`, mirroring
  basecoat's numeric layering:

  | Range | Layer | Example |
  |---|---|---|
  | 10 | core (surface-scoped principles) | `sheen-10-core-design-principles` |
  | 20 | tokens | `sheen-20-tokens-naming` |
  | 30 | components | `sheen-30-components-states` |
  | 40 | web/usability | `sheen-40-web-usability` |
  | 50 | brand | `sheen-50-brand-voice` |
  | 60 | information architecture | `sheen-60-ia-navigation` |
  | 70 | taxonomy/ontology | `sheen-70-taxonomy-ontology` |
  | 80 | content/localization | `sheen-80-content-multilingual` |
  | 90 | standards/conformance | `sheen-90-standards-conformance` |

- **Agents:** `<role>.agent.md`.
- **Prefix `sheen-`** everywhere basecoat uses `basecoat-`.

---

## 8. Skill catalog (target)

Grouped logically; folders stay flat and are indexed in `skills/_catalog.md`.
Implementation breadth (full vs. lean-first) is decided per §11.

**Foundations** — `design-tokens`, `color-system`, `typography`,
`layout-grid-spacing`, `iconography`, `motion-elevation`, `theming`

**Brand** — `brand-identity`, `brand-voice-tone`, `logo-usage`,
`imagery-illustration`

**Information architecture** — `information-architecture`, `wireframing`,
`navigation-design`, `taxonomy`, `ontology`

**Components / UI** — `component-spec`, `ui-states-interaction`,
`pattern-library`, `design-system-audit`

**Web design & usability** — `web-usability-review`, `landing-page-design`,
`responsive-design`, `content-hierarchy`

**Content & localization** — `multilingual` (i18n/l10n), `ux-writing`
(microcopy, content design, labels/errors per NN/g)

**Accessibility** — `accessibility-audit`, `color-contrast-check`

**Security & privacy UX** (design surface of OWASP + ISO/IEC 29184) —
`secure-ux` (safe error/empty states, auth & forgot-password UX, input-validation
feedback, consent & permission patterns, no client-side info leak)

**Mapping / discovery** (inventory an existing codebase, feed `design-audit`) —
`css-mapping` (extract stylesheets/variables and frameworks like Tailwind,
Bootstrap, CSS-in-JS into sheen tokens), `font-mapping` (inventory font families,
weights, and usage; map to typography tokens), `i18n-framework-mapping` (detect
and map multilingual frameworks — i18next, react-intl/FormatJS, gettext, ICU,
Vue-i18n — and locale coverage), `usability-mapping` (inventory flows and screens
against usability heuristics for coverage gaps)

**Lifecycle / operations** (verb-oriented, span all pillars) —
`design-audit` (assess an existing repo/product against sheen: tokens, brand, IA,
a11y, usability), `design-bootstrap` (start a design system from scratch),
`design-update` (evolve/modernize an existing system), `design-suggest` (propose
targeted, prioritized improvements), `design-debate` (structured tradeoff debate
between competing options), `design-exploration` (generate and shape new concepts),
`design-handoff` (package tokens, component specs, and redlines for engineering)

**Governance / meta** — `style-guide-authoring`, `design-review`,
`craft-quality`, `create-design-skill`, `user-research` (personas, interviews,
usability testing per NN/g), `visual-regression` (design QA / snapshot diffing)

**Scope note — lifecycle vs. pillar skills:** the lifecycle skills are broad,
repo/product-wide entry points that orchestrate the pillar skills. They delegate
to focused skills for depth — e.g. `design-audit` first runs the mapping skills
(`css-mapping`, `font-mapping`, `i18n-framework-mapping`, `usability-mapping`) to
inventory the codebase, then `design-system-audit`, `accessibility-audit`, and
`web-usability-review` to assess it; `design-review` remains the single-artifact
critique, while `design-debate` compares multiple options.

Each skill ships: `SKILL.md` (frontmatter with USE FOR / DO NOT USE FOR triggers),
`eval.yaml` (≥3 positive, ≥2 negative routing scenarios), and `templates/` when
starter assets reduce repeated work.

---

## 9. Agents (target)

`brand-steward`, `design-system-architect`, `ux-designer`,
`information-architect`, `accessibility-auditor`, `design-reviewer`. Each composes
the relevant skills + instructions and carries an eval file.

---

## 10. Consumption, validation & CI

- **`.sheen.yml`** in a consumer repo selects source ref and allow-lists of
  skills / agents / instructions / token themes; `sync.*` pulls them in.
- **`checks.json`** drives advisory validation: frontmatter completeness, token
  schema + a11y gates, catalog/metadata drift.
- **CI (`.github/workflows`):** run skill/agent evals, token lint + contrast gate,
  markdown lint, build `sheen-metadata.json`, deploy docs.
- **`rollback.*`** reverts a sync to a prior pinned ref.

### 10.1 CI/CD & onboarding profile (`solo-dev`)

The repo is onboarded with the **solo-dev** profile (see
[`.github/PROFILE.md`](.github/PROFILE.md) and
[`.github/sheen-onboarding-profile.json`](.github/sheen-onboarding-profile.json)),
mirroring basecoat's profile model in `vendor/basecoat/scripts/bootstrap.ps1`
(`branch_policy: minimal`, `workflow_pack/template_pack: solo`,
`telemetry_mode/secrets_mode: local`, `hook_pack: none`).

basecoat ships **~95 org-scale workflows**; sheen's **solo pack** keeps only:

- `ci.yml` — `lint-and-validate` (skill/agent/instruction frontmatter, naming,
  catalog drift) + `tokens` (DTCG JSON validity).
- `docs.yml` — mkdocs strict build when configured.

All steps **exclude `vendor/`** and **no-op gracefully** until root assets exist,
so CI is green pre-implementation. No *repo-level* branch protection is added.

**Enterprise EMU governance (authoritative).** basecoat-sheen runs on a **shared
enterprise EMU instance**, so the `solo-dev` profile governs only the local
authoring ceremony (workflow/template pack, local telemetry/secrets, no hooks) —
**not** merges. Enterprise/org rulesets govern `main` and supersede
`branch_policy: minimal`: PR required (no direct push/force-push/deletion), CodeQL
code scanning + code quality must pass, Copilot code review on push, all Actions
SHA-pinned, and an agent-file path restriction. These rulesets have **no bypass
actors** for the security checks, so there is **no admin/self bypass** — merges go
through passing checks. Excluded upstream workflows (portal-deploy, release-train,
governance-enforce, memory-sweep, adoption-metrics, reviewer-autoassign, cross-repo
sync, org secret gates) remain out of scope.

---

## 11. Delivery phases

Phasing to be confirmed with the owner. Proposed:

- **Phase 0 — Scaffold:** governance files (`docs/design-context.md`, `.lexicon.md`,
  `.sheen.yml.example`, `checks.json`, `sheen-metadata.json`, README/CONTRIBUTING),
  empty pillar dirs, sync/rollback, CI skeleton.
- **Phase 1 — Token system:** `tokens/` core + semantic + light/dark themes,
  `validate-tokens`, contrast gate.
- **Phase 2 — Core skills (~8):** `design-audit`, `design-bootstrap`,
  `design-tokens`, `color-system`, `component-spec`, `accessibility-audit`,
  `web-usability-review`, `create-design-skill` (+ evals). These two lifecycle
  entry points (`design-audit`, `design-bootstrap`) cover the "audit existing" and
  "start from scratch" paths first.
- **Phase 3 — Agents & remaining skills:** full catalog per §8–§9.
- **Phase 4 — Docs site & portal:** mkdocs foundations/brand/components/a11y.

---

## 12. Gap audit (v0.1)

Findings from auditing the spec against the influence set (incl. Fluent 2):

| Gap found | Resolution |
|---|---|
| No **state tokens** (hover/pressed/selected/disabled/focus) | Added to `semantic/` tier (§6) |
| No **high-contrast** theme | Added to `themes/` + stricter contrast gate (§6) |
| Token vocabulary didn't name the **global vs. alias** model | Mapped core→global, semantic→alias (§6) |
| Web-only tokens, no **cross-platform** output | Added Style-Dictionary build step (§6) |
| No **content design / UX-writing** skill (NN/g error/label guidance) | Added `ux-writing` (§8) |
| No **design→engineering handoff** skill | Added `design-handoff` (§8) |
| Fluent 2 not credited as a source | Added to influences (§2) |
| No **user-research / personas** skill | Added `user-research` (§8) |
| No **design QA / visual-regression** skill | Added `visual-regression` (§8) |
| No **materials / translucency** foundation (Mica/Acrylic) | Added to `core/` tokens (§6) |
| **Geometry/shape** not named as a foundation | Named in `core/` tokens (§6) |
| No named **design-values** set to appeal to in reviews | Adopted Windows 11 + M3 values (§2) |
| No formal **standards conformance** (WCAG/ARIA/ISO/OWASP) mapping | Added spec 08 + `secure-ux` skill + band-90 instruction (§2, §7, §8) |

Still open / deferred: an optional memory-sweep config in `.sheen.yml` (basecoat
has one) and a design-ops/telemetry surface. Tracked as candidates for a later
phase, not v1 blockers.

---

## 13. Open decisions

| # | Decision | Status |
|---|---|---|
| D1 | Ship validated `tokens/` system | **Confirmed: yes** |
| D2 | Initial skill breadth (full / lean / scaffold-first) | Open |
| D2 | Initial skill breadth (full / lean / scaffold-first) | **Confirmed: full breadth — all 46 skills shipped** |
| D3 | Standalone repo vs. basecoat subtree | **Confirmed: standalone sibling** |
| D4 | Token format = DTCG JSON, aligned with M3 + Fluent 2 | **Confirmed: DTCG JSON, three-tier (core / semantic / themes)** |
| D5 | License | **Confirmed: MIT (matching basecoat)** |
| D6 | Docs stack = mkdocs (match basecoat) | **Confirmed: mkdocs-material** |
| D7 | Conformance baseline = WCAG 2.2 AA + ISO 9241/25010 + OWASP UX (spec 08) | **Confirmed: WCAG 2.2 AA + ISO 9241/25010 + OWASP UX** |
| D8 | Integrate basecoat by **vendoring** it into `vendor/basecoat/` | **Confirmed: yes** |
| D9 | CI/CD onboarding profile = **solo-dev** (local authoring ceremony only). Runs on a **shared enterprise EMU instance**; enterprise/org rulesets (PR-required, CodeQL + code-quality, Copilot review, SHA-pinned actions, agent-path restriction) are the authoritative merge governance — no admin/self bypass. | **Confirmed: yes** |
