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

### 1.1 Complete skill payload evidence

The additive `sheen-metadata/v1` skill inventory preserves `hash` as the
normalized **SKILL.md-only** SHA-256 for compatibility. It does **not** establish
that a whole skill is unchanged. Consumers comparing complete skills MUST compare
the entire `files` array (paths, hashes, and hash modes), not only `hash`.
The existing sync manifest separately records managed file paths and the source
commit; it does not consume these hashes or prove content currency.

Every skill entry includes `files: [{path, hash, hash_mode}]`: all regular bundled
files in that skill folder, including `SKILL.md`, `eval.yaml`, root-level assets,
`references/`, `templates/`, `samples/`, and executable supporting scripts.
Paths are skill-folder-relative with `/` separators, sorted case-sensitively
using ordinal comparison; additions, deletions, renames (including case changes),
and content edits all invalidate `build-metadata -Check`. Discovery includes
hidden payload files and the consumer `.github/skills` root when
`.sheen/manifest.json` exists, using the builder's existing source/consumer mode.
This does not change the manifest-owned scope of the separate W04 diagnostic.

`Get-Hash` applies the existing decoded-text, leading-BOM removal and CRLF→LF,
UTF-8 SHA-256 normalization (`hash_mode: text-lf`) to these text extensions:
`.md`, `.markdown`, `.txt`, `.json`, `.jsonc`, `.yaml`, `.yml`, `.toml`, `.xml`,
`.svg`, `.html`, `.htm`, `.css`, `.scss`, `.sass`, `.less`, `.js`, `.jsx`, `.ts`,
`.tsx`, `.mjs`, `.cjs`, `.ps1`, `.psm1`, `.psd1`, `.sh`, `.bash`, `.py`, `.rb`,
`.go`, `.rs`, `.cs`, `.sql`, `.csv`. Other extensions (including extensionless
assets) use exact byte SHA-256 (`hash_mode: bytes`), never lossy text decoding.
Empty files are valid payloads. No culture-dependent ordering or timestamps
participate in the evidence.

At every depth, exclude dependency/build/local directories `.git`, `node_modules`,
`dist`, `build`, `.venv`, `venv`, `__pycache__`, `.cache`, `.pytest_cache`,
`.mypy_cache`, `.ruff_cache`, `coverage`, `site`, `test-results`,
`playwright-report`; exclude files `.git`, `.gitkeep`, `.DS_Store`, `Thumbs.db`,
`.env*`, `*.local`, `*.local.*`, `*.log`, `*.tmp`, `*.bak`, `*.pyc`.
These reserved noise locations MUST NOT hold operative skill contracts.
Other hidden files remain included. Symlinks/reparse points in the payload fail
generation rather than following external content or silently asserting currency.
Assets outside the skill folder do not contribute to its file inventory.

`scripts/test-build-metadata.ps1` runs the actual builder and `-Check` in isolated
source/consumer git fixtures under ignored `dist/`, verifies reference-only
edit/add/delete/rename drift and regeneration, text/BOM normalization, binary
bytes, stable ordering and noise exclusions, then removes its fixtures.
CI and `checks.json` gate this regression suite. The builder and test are internal
source tooling stripped from the public mirror; source script execution with
the fixture/consumer repository as cwd does not require copying the builder.

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
- **accessibility-routing (W04)** — positive accessibility routing scenarios with
  no resolved specialist relationship, or evidence that cannot be evaluated
  (section 3.1). This is not the artifact-content check below.
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

### 3.1 Advisory routing diagnostics

Run `pwsh scripts/warn-rules.ps1` at a source checkout, or pass
`-RepoRoot <consumer-root>` to that same source script. It loads the adjacent
`eval-routing-lib.ps1`; these internal audit scripts are not provisioned by sync
or included in the public mirror. No copied standalone-script guarantee applies.

W03 retains its existing **greater than 2500 body characters** heuristic
(frontmatter removed, lines joined by LF), approximately 500 tokens; it is not a
tokenizer or a hard gate. Move detail to linked skill-local references/templates,
not out of the contract.

W04 reads supported block/inline eval scenarios through the shared routing
parser. Only **positive** inputs mentioning ARIA, keyboard, screen reader or
focus ring trigger relationship checks. Negative scenarios are anti-triggers,
not requests for the evaluated skill to own accessibility.

A route resolves when the evaluated skill is composed by the installed,
correctly named `accessibility-auditor`, directly pairs with that agent, or
directly pairs with one of that agent's existing, correctly named composed
skills (for example, `accessibility-audit` or `color-contrast-check`). Pair
declarations are leading backticked asset names in bullets or first table cells
under **Delegates / pairs with**, or a bare single-name bullet; `agent:` is
supported, as are legacy **Agent Pairing** bullets with explicit `Feeds:` lists.
Description, example and eval mentions are not declarations. Do not
infer arbitrary transitive routes through peers. This heuristic establishes
declared availability, not adequacy for a particular request, executed handoff,
or WCAG conformance; criterion-level evidence remains required.

The eval's `skill` must identify its own existing sibling skill. Consumer copies
may retain the source `skills/<name>/SKILL.md` path or use the installed
`.github/skills/<name>/SKILL.md` path. Missing/mismatched assets, invalid eval
records, and unsupported multiline inputs produce advisory diagnostics rather
than successful routing claims. Eval inputs use single-line scalars.

Source scans include root skills and agents only. In consumers, W02-W05 use
`.sheen/manifest.json` (`sheen-manifest/v1`, `files` array) to include only
Sheen-owned skill/eval/agent files, not installed BaseCoat or local content.
An invalid manifest warns that scope is unavailable; an empty owned set is
valid. Missing manifest-owned routing files warn. W01 keeps its semantic-token
directory scope. Missing specialist assets in a selective sync cannot establish
a specialist route.

`scripts/test-warn-rules.ps1` exercises source and consumer fixtures, true
warnings, negative-only cases, missing references, malformed evidence, direct
skill/agent composition and misleading mentions. CI gates regressions in the
checker, then runs the advisory report; actual W01-W05 findings still exit zero.
Operational failures such as an unreadable root or absent helper are errors,
not advisory findings.

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
