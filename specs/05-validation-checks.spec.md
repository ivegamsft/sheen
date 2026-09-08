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

Publication MUST regenerate and check metadata after stripping internal files
and rewriting public identifiers, before the final safety gate and commit.
Retain the trusted builder outside the publish tree for this step; it must not
be shipped merely to refresh payload evidence.

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

### 3.0 Source audit consistency gates

`test-audit-contracts.ps1` reads the operative AI review, ethics checkout and
parity contracts plus parity SKILL guards. It requires nonempty recognized
examples, reconciles actual findings with gate totals and taxonomy/table
severity, and checks applicability/unknown-evidence rules. It rejects negative
mutations of those documents (including fairness/required-ARIA downgrades,
missing criteria, stale totals and image-alt requirements on ordinary text).
N/A requires an applicability reason; missing evidence is UNKNOWN, never a pass.
Both AI and parity contracts expose per-dimension/check results, reasons and
evidence references. Their gate schemas include non-approving UNRESOLVED;
parity pairs `gate_status` with nullable `gate_passed` (null only when unresolved).
Confirmed CRITICAL failures take precedence; otherwise unknown/no-applicable
checks cannot pass. The suite exercises 14 worked gate decisions and rejects
mutated schemas or decisions that collapse unresolved outcomes into approval or
confirmed failure. Existing report consumers must handle these states explicitly.
These are deterministic document-consistency checks, **not** agent behavioral
evaluation, rendered accessibility testing, WCAG proof or downstream approval.
Contract wording changes may require deliberate matching test updates.

`audit-skills-agents.ps1` section 4 uses the shared delegate parser, resolves
root-owned skills/agents first, then only verified entries from the source-only
`scripts/external-delegates.json` registry. The whole-root inventory still
excludes installed/upstream/vendor assets. Registry version 1 declares
provider/kind/name/path; allowed roots are `.github/skills` and `.github/agents`,
with exact kind/name path shapes. Validate schema, duplicate keys/names and
boundaries before accepting declarations. Read only declared bounded headers;
reject traversal/absolute/network paths and link/reparse escapes. Missing or
invalid registry is an error, not an empty-success fallback. Missing, unsafe or
identity-mismatched external targets are visible warnings and remain unverified;
unknown/unregistered delegate references remain advisory warnings.

The audit reports verified `external_resolutions` separately with
source/provider/kind/name/path (no content). Source availability does not imply
consumer installation or authority: downstream execution MUST resolve tools
there. No W04 ownership, delegate parsing scope, transitive graph or production
authority changes are implied. `test-external-delegates.ps1` tests the actual
shared resolver and source integration, including local precedence, true unknowns,
invalid registry/targets, hidden fixtures and link escapes.

Both suites are CI/checks.json gates using existing PowerShell tooling. The
registry, resolver, tests and source auditor (which already depends on an internal
routing helper) are stripped from the public mirror by `INTERNAL_PATTERNS`,
rather than publishing orphaned script dependencies. The publisher still retains
the trusted metadata builder outside the payload and regenerates metadata after
sanitation.

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

### 4.1 Release provenance and completeness

`scripts/test-release-reliability.ps1` is a hard CI/checks.json gate. The existing
PowerShell runner invokes Python's standard-library `unittest`; no added packages
are needed. Bash workflow blocks execute in isolated Git fixtures under `dist/`,
with divergent tag/dispatch versions, changelogs, note generators and sync assets.
The tests verify archived and uploaded bytes, create/rerun paths, history fallback,
invalid/missing/injection-shaped tags, mismatched versions and workflow ordering.
A negative checkout mutation reproduces the original mixed-payload failure.

`release.yml` resolves `inputs.tag || github.ref_name` only through an environment
variable, accepts exact `vX.Y.Z`, requires `refs/tags/<tag>` to exist and checks out
that tag before any payload/version/note operation. A same-named branch is not a
tag. The note generator itself comes from the requested tag; its `GITHUB_SHA`
is overridden with checked-out HEAD so older generators' history fallback cannot
read the dispatch commit. Before the coverage gate and notes run, local tag refs
in the disposable job checkout are limited to the selected tag and the greatest
lower-version exact semver tag that is an ancestor of the selected commit. No
remote refs are modified. This keeps old generators from selecting a future or
unrelated tag as their history baseline; without a predecessor they use initial
history. Fixtures cover non-latest reruns, non-ancestor candidates and the first
release with newer tags present. The ZIP uses the fully qualified selected tag.
No new source-release helper is required inside historical tags.

The public publisher also reads explicit tag input through an environment
variable and requires an exact existing semver tag before checkout, stripping or
mirror writes. Tag pushes use the event tag; an empty dispatch input selects the
highest version-sorted exact semver tag, ignoring prerelease and malformed names.
No valid tag is an error. Execution fixtures cover all three selection paths and
prove invalid or branch-only references cannot produce publication outputs.

`publish-to-production.yml` retains `scripts/publish-release.py` from its initial
workflow checkout **before** checking out the publish tag. This enables dispatch
of older tags that lack the helper. The helper and its regression runners are
internal strip-list entries, never public payload dependencies. The retained
copy is removed by an `always()` cleanup step. Existing trusted metadata-builder
retention, post-sanitization regeneration/checks, public push and protection
restoration ordering remain unchanged.

The release completion gate requires a matching source tag, positive integer ID,
boolean draft/prerelease state, nonblank string notes and a published timestamp;
draft/unpublished, wrong-tag or malformed successful responses fail immediately.
It retries source absence (404), HTTP 408/429/500/502/503/504 and enumerated transient
curl failures (DNS/connect, partial transfer, timeout, send/receive/empty reply).
Each lookup is capped at **8 attempts**, with **10 seconds** between attempts.
Every request has a **10-second connect** and **20-second curl total** timeout,
plus a **25-second subprocess wall-clock** guard. Other statuses, TLS/configuration
errors and malformed responses fail immediately. Public lookup uses the same
transient policy, but **only HTTP 404** permits creation; authorization/server
failures never masquerade as absence.

Source notes are rewritten using the mirror's existing owner/URL mappings before
JSON serialization. A case-insensitive final internal-identifier gate must pass
before any public write. PATCH/POST sets the requested tag, notes, published state
and source prerelease flag. Only the expected 200/201 response with matching
tag/body/state (and existing ID for updates) proves completion. Writes are not
retried automatically because an ambiguous response may hide a successful POST.
Two maximally delayed lookups plus one write are bounded to **565 seconds** of
request/wait budget, within the **10-minute release step** and existing 15-minute
job timeout; preceding mirror work consumes part of that job budget.

Offline tests mock transport commands, not the completion implementation. They
cover immediate/delayed/exhausted readiness, source/public authorization and
permanent/transient errors, invalid bodies/state/tags, create/update/repair,
sanitized Unicode/quoted notes, timeout limits and failed/malformed writes.
They are not proof of live API permissions or publication. On gate failure,
inspect the named tag's source/public releases and workflow logs, correct the
underlying cause, then rerun the publisher for the same tag. A mirror push may
already have completed; a failed completion gate is **not** a successful release.
An ambiguous write requires checking the public release before rerunning.
Roll out via the next explicitly authorized release; rollback via a normal
revert PR. This change does not bump versions, tag, publish or alter protections.

### 4.2 Downstream generated-token hygiene

`scripts/test-downstream-token-hygiene.ps1` is a hard CI/checks.json gate using
Python standard-library `unittest`, Git, Bash and PowerShell. Both actual sync
entry points clone a local upstream into isolated consumer fixtures under `dist/`;
fixture TEMP/TMP/TMPDIR stay there too. A minimal builder verifies source delivery
and writes the four outputs; this is Git/sync integration, not DTCG validation.
The runner first probes `ConvertFrom-Yaml`. When unavailable it uses a strict,
test-local decoder for only the three fixture config scalars (source, ref and
materialize_tokens), never a substitute sync or ignore implementation.

Scenarios verify missing/empty/preexisting/broad/exact ignores, original byte
prefixes including BOM/CRLF/no-final-newline, root and nested negations, tracked
outputs with unchanged index bytes and scoped migration warnings, repeat sync,
disabled materialization, unrelated outputs/source/state/other-tool preservation,
and manifest exclusions. Real `git add -A` proves staging outcomes and new ignore
rules are staged. A mutation removing only the hygiene invocation reproduces the
old accidental staging in each real entry point. Public strip execution tests
verify both source-only regression scripts are absent from the published payload;
trusted post-sanitization metadata generation remains unchanged.

## 5. Advisory philosophy

Content/craft rules are advisory (`warn`) so authors aren't blocked by taste;
contract and integrity rules (frontmatter, tokens, drift, references) are hard
`error`s because downstream sync and skills depend on them.
