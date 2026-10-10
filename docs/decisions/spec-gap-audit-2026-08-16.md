# Spec Gap Audit — 2026-08-16

Complete breakdown of all normative specs against their current implementation status.
Issues are logged on GitHub for every unimplemented requirement.

**Audit date:** 2026-08-16  
**Specs reviewed:** Spec 01–09  
**Total gaps found:** 11 (10 new issues + 2 previously tracked)

---

## Summary table

| Spec | Gap | Severity | Issue |
|------|-----|----------|-------|
| 01 | Token build pipeline: DTCG → CSS/JS/TS output | 🔴 High | [#43](https://github.com/ivegamsft/sheen/issues/43) |
| 01 | Semantic layer incomplete: space, elevation, motion, border, interactive-state tokens | 🔴 High | [#44](https://github.com/ivegamsft/sheen/issues/44) |
| 05 | `scripts/contrast-check` not a standalone callable script | 🟡 Medium | [#45](https://github.com/ivegamsft/sheen/issues/45) |
| 02 | Agent eval quality below Spec 02 §7 specificity rubric (>= 7/10) | 🔴 High | [#46](https://github.com/ivegamsft/sheen/issues/46) |
| 03 | `composes.instructions: []` empty on all 6 agents | 🟡 Medium | [#47](https://github.com/ivegamsft/sheen/issues/47) |
| 03 | Agent descriptions are generic template text | 🟡 Medium | [#51](https://github.com/ivegamsft/sheen/issues/51) |
| 05 | Warn-rule scripts not implemented (6 rules in checks.json have no enforcer) | 🟡 Medium | [#48](https://github.com/ivegamsft/sheen/issues/48) |
| 06 | sync.* missing manifest recording and token build step | 🔴 High | [#49](https://github.com/ivegamsft/sheen/issues/49) |
| 08 | No VPAT-style conformance statement template | 🟡 Medium | [#50](https://github.com/ivegamsft/sheen/issues/50) |
| 05 | markdownlint missing; CI workflow names don't match Spec 05 §4 | 🟢 Low | [#52](https://github.com/ivegamsft/sheen/issues/52) |
| 09 | `discriminator` field not in sheen.vocab.yaml | 🟡 Medium | [#40](https://github.com/ivegamsft/sheen/issues/40) *(prev)* |
| 09 | `lint-router.ps1` and `router-contract` CI gate missing | 🟡 Medium | [#41](https://github.com/ivegamsft/sheen/issues/41) *(prev)* |

---

## Spec-by-spec breakdown

### Spec 01 — Token System

**✅ Implemented:**
- Core token files: `color`, `type`, `space`, `radius`, `elevation`, `materials`, `motion` in `tokens/core/`
- Semantic layer: `tokens/semantic/color.tokens.json`, `tokens/semantic/type.tokens.json`
- Theme files: `tokens/themes/light|dark|high-contrast.tokens.json`
- DTCG format validated by `scripts/validate-tokens.ps1` (schema, refs, cycles, tier discipline, contrast, theme completeness)

**❌ Not implemented:**
- **[#43]** No token build pipeline (Style Dictionary or equivalent). Spec §4 requires DTCG → CSS custom properties, JS/TS ESM output. Downstream consumers cannot consume tokens in code.
- **[#44]** Semantic layer has only `color` and `type`. Missing: `semantic/space.tokens.json`, `semantic/elevation.tokens.json`, `semantic/motion.tokens.json`, `semantic/border.tokens.json`. All interactive-state variants need audit.

---

### Spec 02 — Skill Contract

**✅ Implemented:**
- All 46 skills have `SKILL.md` with required frontmatter fields
- All 46 sheen-domain skills have `eval.yaml` with ≥3 positive, ≥2 negative scenarios
- `scripts/lint-frontmatter.ps1` enforces frontmatter, name-matches-folder, description-triggers
- `scripts/audit-evals.ps1` and `scripts/test-eval-routing.ps1` run in CI
- Skill catalog: `skills/_catalog.md` lists all 46 skills; `specs/07-skill-catalog.spec.md` has full per-skill briefs

**❌ Not implemented:**
- **[#46]** Agent eval quality. All 6 `*.agent.eval.yaml` files have generic positive scenarios that do not meet the Spec 02 §7 specificity rubric ("Design-role agent for... Invoke for design requests in this mandate" is the current positive scenario pattern — this is boilerplate).

---

### Spec 03 — Agent Contract

**✅ Implemented:**
- All 6 agents exist with correct frontmatter, body sections (Role, Principles, Playbook, Handoffs, DoD)
- All 6 have `*.agent.eval.yaml` files
- `composes.skills` is populated on all agents
- `reference-integrity` check validates composed skills exist

**❌ Not implemented:**
- **[#47]** `composes.instructions: []` empty on all 6 agents. Spec §2 requires agents to declare composed instructions.
- **[#51]** All 6 agent descriptions use the generic template pattern. Spec §2 requires specific mandate + invoke situation descriptions.

---

### Spec 04 — Instruction Layers

**✅ Implemented (complete):**
- All 10 core instructions present: `sheen-10-*` through `sheen-90-*`
- Correct naming convention (`sheen-<NN>-<layer>-<topic>.instructions.md`)
- `applyTo` field present on all instructions
- `band` and `layer` metadata fields present
- Layer bands 10–90 all have at least one instruction

**❌ Not implemented:** None — Spec 04 is fully implemented.

---

### Spec 05 — Validation & Checks

**✅ Implemented:**
- `checks.json` present with all required `error` rules declared
- `scripts/lint-frontmatter.ps1` enforces rules 1–4, 7
- `scripts/validate-tokens.ps1` enforces rule 5
- `scripts/build-metadata.ps1 --Check` enforces rule 6 (catalog-drift)
- CI runs all three scripts on every PR

**❌ Not implemented:**
- **[#45]** `scripts/contrast-check` does not exist as a standalone callable script. It is embedded in `validate-tokens.ps1`. Spec §3 lists it separately.
- **[#48]** All 6 `warn` rules in `checks.json` have no enforcing scripts: `token-budget`, `description-overlap`, `maturity-docs`, `aria-keyboard-present`, `safe-error-note`, `locale-tags`.
- **[#52]** `markdownlint` not in CI. Spec §4 lists `lint` workflow as including markdownlint.

---

### Spec 06 — Consumption & Sync

**✅ Implemented:**
- `.sheen.yml.example` documents all config keys
- `sync.ps1` and `sync.sh` copy selected assets from upstream
- `rollback.ps1` and `rollback.sh` exist
- `version.json` + `CHANGELOG.md` semver release contract in place

**❌ Not implemented:**
- **[#49]** No sync manifest recorded. `rollback.*` cannot know precisely which files to revert without a manifest.
- **[#49]** No token build step in `sync.*`. Consumers with a `themes:` key in `.sheen.yml` do not get materialized CSS/JS token outputs.

---

### Spec 07 — Skill Catalog

**✅ Implemented (complete):**
- `skills/_catalog.md` lists all 46 skills by pillar
- `specs/07-skill-catalog.spec.md` has per-skill briefs (use-for/workflow/output/pairs) for all 46 skills
- `catalog-drift` CI gate verifies `_catalog.md` == `sheen-metadata.json` == `specs/07`

**❌ Not implemented:** None — Spec 07 is fully implemented.

---

### Spec 08 — Standards & Conformance

**✅ Implemented:**
- Instructions reference applicable standards (WCAG, WAI-ARIA, ISO 9241, DTCG, BCP 47, OWASP)
- `sheen-10-core-accessibility.instructions.md` references WCAG 2.2 AA and WAI-ARIA 1.2
- `sheen-90-standards-conformance.instructions.md` covers cross-cutting standards
- `validate-tokens.ps1` enforces WCAG 2.2 AA contrast (the only machine-testable threshold)

**❌ Not implemented:**
- **[#50]** No VPAT-style conformance statement template. Spec §2.3 requires `accessibility-audit` to produce a conformance statement for procurement regimes (EN 301 549, Section 508).

---

### Spec 09 — Router Contract

**✅ Implemented:**
- Router skill exists at `.github/skills/sheen/` with all 5 required files
- `sheen.vocab.yaml` generated with 46 intents
- `sheen.vocab.yaml` added to `catalog-drift` CI gate
- Five-step resolution chain documented in `references/governance.md` and ADR-002

**❌ Not implemented:**
- **[#40]** `discriminator` field not in `sheen.vocab.yaml`. Required for cross-domain disambiguation per ADR-002.
- **[#41]** `scripts/lint-router.ps1` and `router-contract` CI gate not implemented.

---

## Implementation priority

| Priority | Issues | Rationale |
|----------|--------|-----------|
| 🔴 P0 — Blocks consumers | #43, #44, #49 | No token build = no CSS output; incomplete semantic layer = broken token contracts; no manifest = rollback is unsafe |
| 🔴 P1 — Breaks CI intent | #46, #51 | Generic agent evals and descriptions mean routing is untested and descriptions mislead users |
| 🟡 P2 — Spec compliance | #40, #45, #47, #48, #50 | Required by spec; not blocking current usage |
| 🟢 P3 — Housekeeping | #41, #52 | CI alignment and router contract enforcement |
