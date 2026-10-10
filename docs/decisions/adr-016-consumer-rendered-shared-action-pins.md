# ADR 016 - Consumer-rendered immutable pins for shared sync actions

Status: Accepted by maintainer decision on issue #304, 2026-10-10.

## Context

The existing scheduled consumer workflow called a reusable workflow which cloned
Sheen at runtime. Private consumers therefore needed `SHEEN_FETCH_TOKEN`, while
`GITHUB_TOKEN` could not read the separate internal repository. GitHub Actions
can fetch a referenced action using its own scoped token, but `uses:` refs are
static and cannot be selected from workflow inputs or `.sheen.yml`.

The action source archive also has no `.git` history. It cannot calculate the
containing commit SHA from inside its own runtime or use Git object history to
verify legacy organization-agent migration.

## Decision

1. Use the existing PowerShell and Bash sync engines through a composite
   `sync-assets` action. It consumes the action archive through
   `SHEEN_SOURCE_PATH` and its immutable `SHEEN_SOURCE_COMMIT`; it never clones
   the action source. A unique staging copy protects the action cache.
2. Keep a release tag in the checked-in template as a non-circular placeholder.
   During installation, the existing sync scripts render both action `uses:`
   refs and the `source_commit` input to the resolved source commit. Do not
   embed the commit SHA in the workflow commit containing itself.
3. Preserve the template's repository owner. Source templates use the internal
   action host; public publication sanitation rewrites that host to
   `ivegamsft/sheen`. When consumers sync the private or public source, the
   renderer preserves that corresponding host and pins that source's commit.
4. Discover only published stable releases through the public GitHub API.
   Public consumers resolve action SHA from the public release tag. Internal
   consumers use an additive public `release-provenance.json` source-commit
   mapping because the public sanitized commit differs from the internal source
   commit. Discovery creates a pin-only PR; the pinned assets apply only on a
   later workflow run after the PR is merged.
5. Keep `check-sheen-version-callable.yml` as the documented compatibility
   path for custom sources. It stages the selected source at the resolved ref,
   invokes its root `sync.sh` by absolute path, and uses that checkout's
   resolved commit for the asset sync; it never reuses a consumer-root script or
   downloads the drifting public `main` script. Private-source cloning through
   that workflow still requires the centrally managed `SHEEN_FETCH_TOKEN`.
   Legacy agent ownership checks that require Git history fail visibly when
   invoked from the action archive.
6. Preserve `GITHUB_TOKEN` as the update-token fallback. Explain that PRs
   created with `GITHUB_TOKEN` may suppress downstream workflow runs; use a
   manual dispatch or organization-managed `SHEEN_UPDATE_TOKEN` when needed.

## Consequences

- The default GitHub-hosted action path is token-free for reading Sheen assets.
- A desired tag is a discovery request only; static `uses:` cannot select it in
  the same run. Pin update and asset application are separate phases.
- Publishing must preserve the public action metadata and runtime resolver,
  strip source-only action tests, sanitize internal owners, and publish
  verifiable source-commit provenance.
- Allow-lists, managed manifests, idempotency, workflow opt-in, builders, and
  rollback continue to come from the existing sync scripts rather than a second
  installer implementation.

## Alternatives rejected

- Embedding the release commit SHA in its own workflow/action payload is
  circular and cannot be guaranteed.
- Changing a `uses:` expression from `source_ref` or `main` at runtime is
  unsupported by GitHub Actions.
- Keeping the default workflow clone-based preserves the cross-repository
  token requirement.
- Skipping legacy agent authenticity checks would allow modified consumer files
  to be mistaken for trusted managed assets.
