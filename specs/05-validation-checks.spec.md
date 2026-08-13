# Spec 05 — Validation & Checks

> Normative spec for `checks.json`, `sheen-metadata.json`, and CI gates.
> Implements root SPEC §10.

## 1. `sheen-metadata.json` (generated inventory)

- Built by `scripts/build-metadata`; never hand-edited.
- Enumerates every skill, agent, instruction, and token theme with: name, path,
  pillar/band, maturity, description, and a content hash.
- Consumed by the docs `reference/` catalog and by drift checks.
- **Scope:** scans repo-root assets only. `vendor/` (vendored basecoat) is
  excluded — it carries its own `basecoat-metadata.json` and is validated upstream.

## 2. `checks.json` (validation manifest)

Declares the rule set the validators run. Rules are grouped by severity:

| Severity | Meaning | CI effect |
|---|---|---|
| `error` | Contract violation | Fails the build |
| `warn` | Advisory / craft nudge | Reported, non-blocking |

### 2.1 Required `error` rules

1. **frontmatter-complete** — every `SKILL.md`/`*.agent.md`/`*.instructions.md`
   has all required fields (specs 02–04).
2. **name-matches-folder** — skill `name` == folder name.
3. **description-triggers** — skill description has `USE FOR:` (≥3) and
   `DO NOT USE FOR:` (≥2).
4. **eval-min-scenarios** — each `eval.yaml` has ≥3 positive, ≥2 negative.
5. **token-schema** — token rules 1–6 from spec 01 §6 (schema, refs, naming,
   contrast, theme completeness, tier discipline).
6. **catalog-drift** — `skills/_catalog.md`, `sheen-metadata.json`, and the
   per-skill entries in `specs/07-skill-catalog.spec.md` list the same set.
7. **reference-integrity** — every `composes.skills` / `delegates` name resolves
   to an existing asset.

### 2.2 Suggested `warn` rules

- **token-budget** — `SKILL.md` body over ~500 tokens.
- **description-overlap** — high similarity between two skill descriptions.
- **maturity-docs** — a `stable` asset lacking a docs page.
- **aria-keyboard-present** — a `component-spec`/`ui-states-interaction` artifact
  missing an ARIA role/keyboard section (WAI-ARIA APG, spec 08 §2.2).
- **safe-error-note** — an error/empty-state spec lacking a "no-information-leak"
  note (OWASP error handling, spec 08 §2.11).
- **locale-tags** — localized strings not using BCP 47 tags (spec 08 §2.9).

Standards with a machine-testable threshold (WCAG contrast) are `error` rules; the
rest of the standards in spec 08 are advisory `warn`s here plus process guidance in
the relevant skills/instructions.

## 3. Scripts

| Script | Responsibility |
|---|---|
| `scripts/lint-frontmatter` | Rules 1–4, 7 |
| `scripts/validate-tokens` | Rule 5 (spec 01) |
| `scripts/build-metadata` | Generates `sheen-metadata.json`; rule 6 diff |
| `scripts/contrast-check` | Contrast portion of rule 5 (callable standalone) |

Scripts MUST be runnable locally and in CI with identical results.

## 4. CI workflows (`.github/workflows`)

| Workflow | Runs |
|---|---|
| `eval` | Skill + agent routing evals |
| `token-lint` | `validate-tokens` + `contrast-check` |
| `lint` | `lint-frontmatter` + markdownlint + catalog-drift |
| `docs-deploy` | Build `sheen-metadata.json`, deploy mkdocs |

Merges to the default branch require `eval`, `token-lint`, and `lint` to pass.

## 5. Advisory philosophy

Content/craft rules are advisory (`warn`) so authors aren't blocked by taste;
contract and integrity rules (frontmatter, tokens, drift, references) are hard
`error`s because downstream sync and skills depend on them.
