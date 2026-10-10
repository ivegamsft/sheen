# Spec 06 — Consumption & Sync

> Normative spec for `.sheen.yml`, `sync.*`, and `rollback.*`. Implements root
> SPEC §10. Basecoat-compatible so a consumer can adopt both frameworks the same
> way.

## 1. `.sheen.yml` (consumer config)

Placed at a consumer repo root. All keys optional; omit to accept defaults.
A `.sheen.yml.example` in this repo documents every key.

```yaml
# -- Sync configuration --
source: https://github.com/YOUR-ORG/basecoat-sheen.git   # upstream (or private fork)
ref: main                                                 # branch or release tag (pin for stability)
agent_distribution: organization                         # default; repository is explicit compatibility
install_sync_workflow: false                              # default; true deploys/updates scheduling

# Allow-lists — omit a key to sync ALL of that asset type.
skills:        [design-audit, design-tokens, accessibility-audit]
agents:        [design-reviewer]
instructions:  [sheen-10-core-design-principles, sheen-40-web-usability]
themes:        [light, dark, high-contrast]               # token themes to pull

sync:
  script: scripts/sheen/sync-sheen.ps1   # override if not root sync.*
  exclude:
    - archive/
```

Rules:
- `source`/`ref` select the upstream and version. Consumers SHOULD pin `ref` to a
  release tag in production.
- Each allow-list, when present, is an explicit include set; when absent, all
  repository-distributed assets of that type sync. `agents` applies only in
  explicit `agent_distribution: repository` compatibility mode.
- `themes` selects which token themes are materialized in the consumer.

## 2. `sync.*` (`sync.ps1` / `sync.sh`)

- Clone/fetch `source` at `ref`, resolve allow-lists, and copy selected assets
  into the consumer's customization directory.
- MUST be idempotent: re-running with the same config yields the same tree.
- MUST record what it wrote (a manifest) so `rollback.*` can revert precisely.
- Runs token build (spec 01 §4) if the consumer opts into materialized tokens.
- PowerShell and shell entry points MUST stay behavior-equivalent.

### 2.0 Agent distribution and scheduled workflow

- `agent_distribution` MUST default to `organization`; only `organization` and
  `repository` are valid. Organization mode MUST NOT project agents into the
  consumer repository. Organization owners MUST establish their own central
  channel before migration; this source publishes `ivegamsft/.github-private`.
- Publish only pinned release `agents/*.agent.md` definitions, not eval files,
  through central PRs. Record source/ref/commit and SHA-256 hashes in
  `sheen-agents-manifest.json`; preflight all collisions and modified owned
  files before updating/removing anything. Preserve unrelated definitions.
- Organization-mode migration MUST remove only prior manifest-owned agent files
  verified against the previous immutable source commit. Source changes,
  unverifiable/modified files, staged or unstaged edits, and non-regular paths
  MUST fail visibly before any agent removal. Missing owned files drop out of
  the next manifest. Unrelated/custom agents MUST survive.
- `install_sync_workflow` MUST default to false and accept only true/false.
  When true, install/update the marker-owned workflow with the resolved source
  SHA. The default workflow MUST use the `sync-assets` composite action; sync
  scripts MUST render its action ref and `source_commit` input to the same
  40-character SHA. Preserve the selected action owner in public templates;
  publishing sanitizes internal owners to `ivegamsft/sheen`. Otherwise never
  install/recreate/update it. Preserve existing managed workflow bytes and
  ownership entries, and warn that deleting it is required to stop its
  schedule; after deletion, the next manifest drops that entry.
- The released template MAY use its release tag as a non-circular placeholder.
  An installed workflow MUST pin both `sync-assets` and `discover-release` to
  the resolved immutable source commit; a release MUST NOT require a workflow
  to contain the commit SHA of the commit that contains that workflow.
- Release discovery MUST resolve only a published stable `vX.Y.Z` tag from the
  public release API. An optional dispatch tag is a discovery request, not a
  runtime action ref. Discovery may open a pin-only PR but MUST NOT apply the
  newly selected assets in that same run. A later run using the merged SHA
  applies the release. The public workflow MUST resolve public action SHAs from
  public Git refs; private-source action SHAs MUST come from published
  provenance, because the source and sanitized mirror commits differ.
- The token-free composite action MUST use the packaged local payload and
  MUST NOT clone the source repo. It MUST pass paired `SHEEN_SOURCE_PATH` and
  `SHEEN_SOURCE_COMMIT` values to the existing PowerShell/Bash sync engine,
  validate the full commit SHA and required payload, and stage a private copy
  in a unique directory without mutating the action cache. Existing allow-list,
  manifest ownership, idempotency, build, workflow opt-in, and rollback
  semantics remain shared with the scripts. If an organization-mode legacy
  agent requires Git history to verify ownership, local-archive sync MUST fail
  visibly and direct the consumer to the documented clone compatibility path;
  it MUST NOT weaken verification.
- The existing reusable `check-sheen-version-callable.yml` workflow remains a
 documented compatibility path for custom sources, including non-GitHub Git
 remotes. Its private-source clone path continues to use the centrally managed
 `SHEEN_FETCH_TOKEN` for internal sources; the default shared-action path does
 not need that credential. The callable MUST stage its selected
 source at the resolved ref, invoke that checkout's root `sync.sh` by absolute
 path, and use the checkout's resolved commit for the asset sync. It MUST NOT
 execute a consumer-root `sync.sh` or download a drifting `main` script.
 Consumer PRs created with `GITHUB_TOKEN` may not trigger downstream
 workflows; document manual dispatch or an organization-managed
 `SHEEN_UPDATE_TOKEN` when downstream triggering is required. The
 `GITHUB_TOKEN` fallback remains supported.
- Release automation MUST fail visibly without `SHEEN_ORG_AGENTS_TOKEN`, scoped
  to Contents and Pull requests read/write on the central repository. Source
  release reads use the source workflow token. No direct-main push or protection
  bypass is permitted. Publication PR merging remains governed separately.

### 2.1 Generated-token Git hygiene

When token materialization runs, sync MUST protect only these root-relative outputs:

```gitignore
/dist/tokens/sheen.css
/dist/tokens/sheen.js
/dist/tokens/sheen.esm.js
/dist/tokens/sheen.d.ts
```

- Use native Git effective ignore evaluation (`check-ignore --no-index`, including
  tracked paths). Existing broad coverage MUST NOT cause unnecessary edits.
- Preserve effective consumer negations, including nested `.gitignore` overrides,
  and warn that explicitly included outputs may be staged/versioned. Verbose
  `check-ignore` can succeed for a negation; its exit code alone is not ignore proof.
- Append only necessary exact rules to the root `.gitignore`; never blanket-ignore
  `dist/` or `dist/tokens/`. Preserve its existing bytes, BOM, comments and newline
  style; add a separator if its last line has no newline. Repeated sync adds nothing.
- Disabled materialization MUST NOT change `.gitignore`. Ignore rules MUST NOT
  prevent the builder from generating local outputs.
- Automatically remove clean, verified Sheen-generated tracked remnants from
  version control under the default policy using a non-forced, exact-path
  `git rm --cached -- <outputs>`; stage their deletions and regenerate current
  local ignored artifacts. Unrelated index entries MUST remain unchanged.
- Preflight all four outputs before ignore/index mutation or token rebuilding.
  Existing output files MUST have their filename-specific Sheen generator header
  (`generated by scripts/build-tokens.ps1; do not hand-edit`); reject non-regular
  files and ambiguous/custom ownership. On Unix, inspect symbolic links (including
  dangling links) and regular-file type before opening output headers; FIFOs must
  fail without blocking. Tracked output worktree or staged edits
  MUST block cleanup/build visibly without altering those files, ignore rules or
  the index. Consumers preserve/review conflicting work before retrying.
- Before trusting diff results, inspect tracked token entries using `git ls-files
  -v`. Either `assume-unchanged` or `skip-worktree` (including both together) MUST
  block token cleanup/build even if the file appears clean or is explicitly
  included. Name the flagged path and flags in the diagnostic. Never clear flags
  automatically; preserve index bytes, flags and local files on refusal.
- Effective `!` inclusions opt into deliberate versioning and MUST prevent index
  removal of those outputs. Clean included generated outputs may rebuild normally;
  dirty/staged included outputs also block rebuilding rather than lose edits.
  Ordinary source sync may already have completed when token preflight fails.
- Neither `.gitignore` nor generated outputs belong in the ownership manifest;
  rollback MUST NOT own or delete the consumer's ignore file.
- Bootstrap guidance MUST include committing `.gitignore` when present, without
  giving an unconditional missing-path `git add`. Consumer `git add -A` stages new
  ignore rules and retains automatic generated-remnant deletions; regenerated
  ignored local artifacts MUST NOT be re-added. Included outputs stay trackable.

`.sheen/` is intentional sync state; `sheen/tokens/` and `sheen/templates/` are
intentional source assets. The default skill destination is `.github/skills/`,
not `.agents/skills/`. Preserve other tools' assets and unrelated application
outputs. Consumers regenerate ignored outputs during builds (see the
[consumer lifecycle guide](../docs/guides/consumer-lifecycle.md#generated-token-policy)).

## 3. `rollback.*` (`rollback.ps1` / `rollback.sh`)

- Reverts the last sync (or to a named prior manifest/ref).
- MUST not touch consumer-authored files outside the recorded manifest.

## 4. Versioning contract

- This repo publishes releases via `version.json` + `CHANGELOG.md` (semver).
- Breaking changes (renamed/removed published skill, agent, semantic token, or
  theme) require a major bump and a CHANGELOG migration note.
- Consumers pinned to a tag are insulated until they move `ref`.

## 5. Relationship to basecoat

`.sheen.yml` intentionally parallels `.basecoat.yml`; a repo may carry both. The
two sync mechanisms share conventions, but BaseCoat replaces shared `.github`
paths: consumers MUST run BaseCoat first and Sheen last after every full refresh.
Sheen adds the `themes` key and token materialization, which
basecoat has no equivalent for.

## 6. Vendored basecoat

basecoat is vendored at `vendor/basecoat/` (root SPEC §3.1). Two ways a consumer
gets basecoat alongside sheen:

1. **Bundled** — sync from this repo and pull the vendored `basecoat-*` assets
   directly (single source, pinned together).
2. **Independent** — the consumer syncs basecoat from its own upstream via
   `.basecoat.yml` and syncs sheen via `.sheen.yml`. Because namespaces never
   collide (`basecoat-*` vs `sheen-*`), both resolve cleanly when Sheen runs last.

The vendored tree is read-only here and excluded from sheen's validation and
metadata scans (spec 05 §1).
