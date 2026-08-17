# Consumer Lifecycle Guide

> **Purpose:** A single, end-to-end prompt playbook for adopting sheen into your
> project. Paste any phase prompt into GitHub Copilot CLI (or Copilot Chat with
> the sheen agent active) and the agent will drive the work.

This guide covers five phases: **Integrate → Onboard → Inventory → Audit → Use.**
You can run them sequentially for a new adoption, or jump to any phase in an
existing project.

---

## Phase overview

| Phase | Goal | Who runs it | Time |
|-------|------|-------------|------|
| [1 — Integrate](#phase-1-integrate) | Wire sheen assets into your repo | Engineer / lead | ~30 min |
| [2 — Onboard](#phase-2-onboard) | Configure team workflow & CI gates | Lead / DevOps | ~1 hr |
| [3 — Inventory](#phase-3-inventory) | Scan and report current design-system coverage | Any team member | ~15 min |
| [4 — Audit](#phase-4-audit) | Validate tokens, WCAG, skill & agent compliance | Designer / QA | ~1 hr |
| [5 — Use](#phase-5-use) | Day-to-day design work with the right agent | Designer | ongoing |

---

## Phase 1 — Integrate

**Goal:** Pull sheen assets into your consumer repo for the first time.

### Prompt

```text
I want to integrate basecoat-sheen into my repo at <YOUR-ORG>/<YOUR-REPO>.

Please:
1. Create a .sheen.yml at the repo root configured for <TEAM-SIZE: solo|team|org>,
   pinned to ref: main (or <release-tag> for production stability).
2. Run sync.ps1 (Windows) or sync.sh (POSIX) to pull the selected assets.
3. Confirm what was synced by reading .sheen/manifest.json.
4. Verify the sync was successful by running scripts/diagnose-sheen.ps1.
5. Summarise what was installed, what was skipped, and any errors to resolve.

Target asset set: <ALL | subset: skills, agents, tokens, instructions>
Themes to materialise: <light, dark, high-contrast | all>
```

### What the agent does

1. Generates a `.sheen.yml` with `source`, `ref`, and allow-lists matched to your team size.
2. Invokes `sync.ps1` or `sync.sh`, which clones the upstream at `ref` and copies assets.
3. Reads `.sheen/manifest.json` to confirm files written.
4. Runs `scripts/diagnose-sheen.ps1` to validate the installed state.
5. Returns a summary report: installed count, skipped assets, errors.

### Output

- `.sheen.yml` — your consumer config (commit this)
- `.sheen/manifest.json` — sync manifest (commit this)
- `.github/skills/<name>/` — synced skill folders
- `.github/agents/<name>.agent.md` — synced agent files
- `.github/instructions/<name>.instructions.md` — synced instruction files
- `sheen/tokens/` — synced DTCG token source
- Console summary from `diagnose-sheen.ps1`

### Gate ✅

Diagnose passes with 0 errors before moving to Phase 2.

---

## Phase 2 — Onboard

**Goal:** Configure the team workflow, add CI validation gates, and verify the
first design-system skill runs end-to-end.

### Prompt

```text
I've synced basecoat-sheen into <YOUR-REPO>. Help me onboard the team.

Please:
1. Recommend an adoption pattern for my team: <DESCRIBE-CONTEXT, e.g.
   "3 designers + 5 engineers, shared monorepo, shipping a design system">.
2. Set up CI validation: add validate-tokens and eval-routing to our pipeline.
3. Add materialize_tokens: true to .sheen.yml if we need CSS/JS output.
4. Run the token build pipeline (scripts/build-tokens.ps1) and show me the
   first CSS output.
5. Verify one skill end-to-end: invoke the design-tokens skill on our tokens/
   folder and return a gap report.
6. Create a team onboarding checklist tailored to our context.
```

### What the agent does

1. Reads your team context and maps it to a [consumption pattern](consumption-patterns.md) (Solo / Cross-Functional / Cross-Org / Token-Only).
2. Adds CI steps for `validate-tokens` and `eval-routing` to your workflow file.
3. Updates `.sheen.yml` with `materialize_tokens: true` if opted in.
4. Runs `scripts/build-tokens.ps1` → emits `dist/tokens/sheen.{css,js,esm.js,d.ts}`.
5. Invokes `@design-system-architect` via the `design-tokens` skill against your token source.
6. Generates a checklist: team responsibilities, training links, sprint 1 priorities.

### Output

- `.github/workflows/ci.yml` — with token validation and eval routing gates
- `dist/tokens/sheen.css` — first CSS output (add to `dist/` gitignore)
- Design-tokens gap report (missing semantic layers, naming violations)
- Team onboarding checklist (Markdown, commit to `docs/`)

### Gate ✅

CI passes on `main`; at least one skill runs without errors before Phase 3.

---

## Phase 3 — Inventory

**Goal:** Produce a current-state report of design-system coverage — what's
installed, what's in use, what's missing, and what's drifted.

### Prompt

```text
Inventory the current basecoat-sheen adoption state for <YOUR-REPO>.

Please report:
1. Installed assets: which skills, agents, and instructions are in .github/.
2. Token coverage: which semantic token tiers (color, type, space, elevation,
   motion, border) are present and which are missing.
3. Theme completeness: which themes exist and whether all semantic keys resolve.
4. Skill catalog drift: which skills are in .sheen/manifest.json but not in
   the .github/skills/ tree (or vice versa).
5. Instruction layer coverage: which sheen instruction bands (10-90) are active.
6. Summarise coverage as a percentage and flag any critical gaps.
```

### What the agent does

1. Reads `.sheen/manifest.json` to get the installed asset list.
2. Scans `.github/skills/`, `.github/agents/`, `.github/instructions/` against the manifest.
3. Reads `tokens/semantic/` to enumerate which tiers are present.
4. Runs `scripts/validate-tokens.ps1` for theme completeness.
5. Compares `skills/_catalog.md` (upstream) against the installed set.
6. Returns a structured coverage report with percentage score and critical flags.

### Output

```
SHEEN INVENTORY — <repo> @ <date>
─────────────────────────────────────────────────────────
Assets installed:   43 / 52 skills | 6 / 6 agents | 8 / 10 instructions
Token tiers:        color ✅ | type ✅ | space ✅ | elevation ✅ | motion ✅ | border ✅
Theme completeness: light ✅ | dark ✅ | high-contrast ✅ (80 keys × 3 themes)
Catalog drift:      2 skills in manifest not found on disk (⚠ resync needed)
Instruction bands:  sheen-10 ✅ | sheen-20 ✅ | sheen-30 ✅ | sheen-40 ✅ |
                    sheen-50 ✅ | sheen-60 ✅ | sheen-70 ✅ | sheen-80 ✅ |
                    sheen-90 ✅
Overall coverage:   91% — 2 critical gaps flagged
─────────────────────────────────────────────────────────
```

### Gate ✅

Overall coverage ≥ 80%; no critical gaps before Phase 4.

---

## Phase 4 — Audit

**Goal:** Deep validation — token conformance, WCAG accessibility, skill routing
quality, and standards compliance.

### Prompt

```text
Run a full design-system audit for <YOUR-REPO> using basecoat-sheen.

Please:
1. Token audit: run validate-tokens.ps1 and report any schema, reference,
   naming, or WCAG contrast failures.
2. Accessibility audit: invoke @accessibility-auditor to evaluate the
   current token set against WCAG 2.2 AA (and AAA for high-contrast).
3. Eval routing audit: run scripts/audit-evals.ps1 and report any eval
   files scoring below 7.0.
4. Standards conformance: check that sheen-90-standards-conformance
   instruction is active and that agent descriptions include USE FOR /
   DO NOT USE FOR patterns.
5. Spec drift: compare installed skill/agent files against the upstream
   manifest and flag any files that differ from the synced ref.
6. Return a prioritised remediation list (P0 blocks consumers, P1 breaks
   routing, P2 spec compliance, P3 housekeeping).
```

### What the agent does

1. **Token audit** — `scripts/validate-tokens.ps1`: DTCG schema, alias resolution, WCAG contrast pairs.
2. **A11y audit** — `@accessibility-auditor` via `accessibility-audit` + `color-contrast-check` skills.
3. **Eval audit** — `scripts/audit-evals.ps1`: scores all `eval.yaml` files on 7-criterion rubric, flags < 7.0.
4. **Standards check** — validates agent frontmatter for `USE FOR:` / `DO NOT USE FOR:` patterns; checks `composes.instructions` is populated.
5. **Drift check** — `build-metadata.ps1 --Check` compares on-disk state against generated metadata.
6. **Remediation list** — grouped by priority with issue references.

### Output

```
SHEEN AUDIT REPORT — <repo> @ <date>
──────────────────────────────────────────────────────────────
Token validation:   ✅ 80 tokens | 3 themes | 0 errors | all WCAG AA ✅
A11y audit:         ✅ all contrast pairs ≥ 4.5:1 | high-contrast ≥ 7:1
Eval routing:       ✅ 52 files | 286 scenarios | 0 below 7.0
Standards:          ✅ 6/6 agents have USE FOR / DO NOT USE FOR
Drift check:        ⚠ 1 skill file differs from manifest ref
──────────────────────────────────────────────────────────────
Remediation:
  P0  — none
  P1  — none
  P2  — [#40] discriminator field missing from sheen.vocab.yaml
  P3  — [drift] skills/color-system/eval.yaml differs from upstream ref
──────────────────────────────────────────────────────────────
```

### Gate ✅

0 P0 and 0 P1 items before moving to Phase 5.

---

## Phase 5 — Use

**Goal:** Day-to-day design work. Route requests to the right agent or skill
using the sheen router.

### How to invoke

```text
/sheen <keyword> <your request>
```

See the [full Prompt Guide](prompts/index.md) for every agent, skill, and intent.

### Common lifecycle prompts

#### 🎨 Design a new component

```text
/sheen token Design the token architecture for a <button|card|modal|badge>
component: semantic tokens for background, foreground, border, focus-ring,
and all interactive states (hover, pressed, selected, disabled, focus).
Return a DTCG JSON snippet ready for tokens/semantic/.
```

#### 🖼️ Brand alignment check

```text
/sheen brand Audit this design mock for brand consistency: logo placement,
illustration style, and voice alignment with our <brand-voice-tone> guide.
Flag any violations and return a corrected brief.
```

#### ♿ Accessibility review

```text
/sheen a11y Run a WCAG 2.2 AA review on <component-name | screen-description>.
Check: contrast ratios, keyboard navigation order, ARIA roles, focus visibility.
Return a findings table with severity (critical | major | minor) and fix guidance.
```

#### 📐 Usability review

```text
/sheen usability Review the <feature-name> user flow against Nielsen's 10
heuristics. Return a scored heuristic table, top-3 friction points, and
redesign recommendations with acceptance criteria.
```

#### 🗂️ IA restructure

```text
/sheen ia Evaluate the navigation taxonomy for <product-area>. Identify
labelling inconsistencies, orphaned categories, and missing ontology
relationships. Return a revised sitemap and labelling guide.
```

#### ✅ Design governance

```text
/sheen review Run a craft-quality critique of <design-description | file-ref>.
Score against the sheen design bar (Effortless, Calm, Personal, Familiar,
Complete+Coherent). Return a decision package with tradeoffs and next actions.
```

#### 🏭 Factory patterns (multi-agent)

Run multiple agents in parallel or in sequence for complex design reviews:

```text
# Parallel audit (a11y + usability + craft — 3 agents)
/sheen a11y Audit <component> for WCAG 2.2 AA. Return findings table.
/sheen usability Audit <component> for Nielsen heuristics. Return scored table.
/sheen review Run craft-quality critique of <component>. Return decision package.
Synthesise all three into a single prioritised remediation list.

# Serial design chain (debate → decision → a11y check)
/sheen debate Should <component> use inline or modal state for <interaction>?
Use 3-option weighted matrix. Return the recommended option.
Then: /sheen a11y Validate the recommended option against WCAG 2.2 AA.

# Token cascade (new semantic token → brand review → CSS output)
/sheen token Define the semantic token for <new-role>. Return DTCG JSON.
Then: /sheen brand Confirm the token aligns with our brand palette.
Then: /sheen token Build the token and show me the CSS output.
```

---

## Troubleshooting

| Symptom | Likely cause | Fix |
|---------|-------------|-----|
| `sync.ps1` fails with auth error | Private fork needs credential | Set `SHEEN_REPO` env var with auth token in URL |
| `validate-tokens` fails on contrast | Theme pair below WCAG threshold | Check `tokens/themes/` — update hex values to pass 4.5:1 minimum |
| Eval audit scores below 7.0 | Generic or boilerplate input prompts | Add 4+ specific pos/neg scenarios; avoid "Use @agent to…" scaffolding |
| Agent description fails USE FOR check | Legacy template description | Update `description:` in agent frontmatter with trigger phrases |
| `catalog-drift` CI gate fails | `sheen-metadata.json` out of date | Run `scripts/build-metadata.ps1` and commit updated file |
| `build-tokens.ps1` dangling ref error | Semantic token aliases point to missing core key | Check `{...}` path exists in `tokens/core/*.tokens.json` |

---

## See also

- [Prompt Guide](prompts/index.md) — Full 46-intent reference by agent
- [Consumption Patterns](consumption-patterns.md) — Solo / Team / Org adoption paths
- [Token Build & CI](token-build-ci.md) — Wiring token validation into your pipeline
- [Sheen Router](../decisions/adr-001-sheen-router.md) — Router design decision record
- [ADR-001](../decisions/adr-001-sheen-router.md) — Router design decision record
- [Spec Gap Audit](../decisions/spec-gap-audit-2026-08-16.md) — Known gaps and open issues
