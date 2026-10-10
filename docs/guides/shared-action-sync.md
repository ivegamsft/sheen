# Shared action sync and release pins

When `install_sync_workflow: true`, the installed
`.github/workflows/sheen-sync.yml` uses Sheen's composite `sync-assets` action.
GitHub downloads the action at its pinned commit; the consumer workflow does
not clone the source repository, so the default action path needs no fetch token.

## Immutable pins

The checked-in release template uses its release tag as a placeholder. During
sync, the existing `sync.ps1` and `sync.sh` rewrite both action `uses:` refs and
the `source_commit` input to the same resolved 40-character commit. The
generated consumer workflow is immutable; no commit SHA is embedded in the
source commit that contains the template.

Pin rendering preserves the action repository owner already configured in the
consumer template. Public and internal hosts have different commit histories
after public sanitization. Release discovery therefore resolves public action
commits through the public Git API and uses the published
`release-provenance.json` source mapping for internal action commits.

## Two-phase release updates

The installed workflow has two independent jobs:

1. **Discover:** on schedule, query the latest published stable release and
   open a pin-only PR. A manual `source_ref` is an optional `vX.Y.Z` discovery
   request; branch names such as `main` cannot change a static action ref.
2. **Sync:** apply only the action SHA already present in the checked-out
   workflow and open an asset update PR if the existing sync engine reports
   changes.

The discovery job never passes its newly resolved commit to the sync job.
After the pin PR is merged, a later workflow run applies that SHA. The workflow
listens for changes to its managed YAML, but a PR opened with `GITHUB_TOKEN`
may suppress downstream runs. Manually dispatch the workflow after merging, or
configure an organization-managed `SHEEN_UPDATE_TOKEN` with the required
consumer repository contents and pull-request permissions. The workflow keeps
`GITHUB_TOKEN` as its fallback.

## Custom sources and compatibility

The composite action syncs the exact Sheen release bundled with its own pinned
action. It does not select a different `.sheen.yml` `source` or `ref`. For a
custom Git repository, non-Git host, or a source that must be selected
dynamically, retain the documented reusable callable workflow:

```yaml
jobs:
  sync:
    uses: custom-owner/basecoat-sheen/.github/workflows/check-sheen-version-callable.yml@<approved-commit-sha>
    with:
      source_repo: custom-owner/custom-sheen
      source_ref: main
    secrets:
      fetch_token: ${{ secrets.CUSTOM_SOURCE_TOKEN }}
```

The callable path clones the configured source and preserves its existing
`fetch_token` contract. Obtain credentials for a custom private source under
that source owner's authentication policy; the consumer `GITHUB_TOKEN` cannot
clone another private repository. Public sources may be cloned anonymously.
Use this compatibility workflow instead of the shared action when custom-source
selection is required.

For the callable path, the workflow stages the configured Sheen source at its
resolved ref and runs that checkout's root `sync.sh` by absolute path. It does
not execute or overwrite a consumer-root `sync.sh`, which remains owned by the
tool that installed it. The staged script commit is also used for the asset
sync, preventing script and payload drift.

<!-- sheen-internal-only:start -->
For `IBuySpy-Shared/basecoat-sheen`, the callable workflow receives the centrally
managed organization Actions secret `SHEEN_FETCH_TOKEN`. Organization secret
administrators own its provisioning and rotation; consumers must not create a
repository secret with the same name. If inherited access is unavailable, file
an issue with the source maintainers. This read-scoped organization credential
is not a general-purpose token for custom private sources.
<!-- sheen-internal-only:end -->

The action archive intentionally has no Git history. If a previous manifest
owns legacy organization-mode agent copies that still need history-based
authenticity verification, the shared action fails visibly rather than
weakening that check. Use the callable clone path for that one-time migration.

## Existing opt-in and ownership behavior

`install_sync_workflow` remains false by default. When enabled, the sync
scripts continue to manage the marker-owned workflow, manifests, allow-lists,
idempotency, builders and rollback as before. A manually edited/unmanaged
workflow is preserved; delete the managed workflow to stop its schedule.
