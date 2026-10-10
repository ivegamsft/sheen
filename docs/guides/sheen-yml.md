# `.sheen.yml` Guide

`.sheen.yml` controls consumer sync behavior:

- `source` and `ref`
- `agent_distribution`: `organization` by default, or explicit `repository`
  compatibility. Establish your organization's central channel before migration.
- optional allow-lists for `skills`, `instructions`, `themes`; `agents` applies
  only in repository compatibility mode
- `install_sync_workflow`: false by default; true installs/updates the scheduled
  workflow. To stop an existing schedule, keep this off and delete
  `.github/workflows/sheen-sync.yml`; subsequent syncs will not recreate it.
- sync overrides (`script`, `exclude`)

Start from `.sheen.yml.example` at repo root.

When using both layers, run BaseCoat first and Sheen last after every full refresh.
