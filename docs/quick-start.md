# Quick Start (10 Minutes)

basecoat-sheen is the design governance finish coat for basecoat: a reusable set
of skills, agents, instruction layers, prompts, templates, and DTCG tokens that
you can sync into a consumer repository with `.sheen.yml`. In one short setup,
you can adopt only the assets you need now, then expand without changing your
sync model.

This guide gets a new consumer from zero to first sync in five steps, then
points to the three adoption modes:

- [Lean mode](adoption-modes.md#mode-1-lean-solo-or-low-overhead)
- [Token-only mode](adoption-modes.md#mode-2-token-only-design-system-governance-without-ai-assets)
- [Full mode](adoption-modes.md#mode-3-full-cross-functional-maximum-coverage)

## Before you begin (1 minute)

Have these ready:

- A consumer repository where you want design governance assets
- Git and shell access in that repository
- Optional: an existing `.basecoat.yml` (safe to keep; namespaces do not collide)

If you are adopting from a tagged release, prefer pinning `ref` to a version tag
instead of `main`.

## Step 1. Copy config scaffold into your consumer repo (2 minutes)

Create `.sheen.yml` at the root of your consumer repository. Start from the
template below (or copy from `.sheen.yml.example` in this repo).

```yaml
# .sheen.yml
# Minimal starter for first-time onboarding
source: https://github.com/IBuySpy-Shared/basecoat-sheen.git
ref: main

# Optional allow-lists; uncomment as you narrow scope
# skills:
#   - design-review
#   - token-audit
# instructions:
#   - sheen-10-core-design-principles
# themes:
#   - light
#   - dark
```

Expected state after this step:

```text
your-consumer-repo/
  .sheen.yml
  ...
```

If you already use basecoat, keep `.basecoat.yml` as-is. basecoat and sheen use
separate prefixes (`basecoat-*` and `sheen-*`), so both can be synced together.

## Step 2. Run sync from the consumer repo (2 minutes)

From the consumer repository root, run the sync entrypoint for your platform.
Use the script your team standardizes on.

```powershell
# Windows
./sync.ps1
```

```bash
# macOS / Linux
./sync.sh
```

If your repo uses a custom sync path, run that path instead:

```powershell
./scripts/sheen/sync-sheen.ps1
```

You should see output indicating copied or updated sheen assets based on your
`.sheen.yml` selection. If your first run is broad (no allow-lists), that is
expected. Narrow later by editing allow-lists.

## Step 3. Verify what landed (2 minutes)

After sync, verify the expected directories and metadata are present in your
consumer repository.

```bash
# quick check
ls skills agents instructions tokens
```

```bash
# optional git-focused check
git status --short
```

You are looking for some or all of these, depending on mode:

```text
skills/
agents/
instructions/
tokens/
checks.json
```

If you selected a narrow profile and see fewer directories, that is correct.
The scope comes from your `.sheen.yml` allow-lists.

For token-heavy adoption, run your existing token validation or CI check after
sync to confirm references and theme completeness in your consumer workflow.

## Step 4. Explore the synced assets (2 minutes)

Once files are present, orient quickly before integrating into team workflows.
Start with catalog and guides, then inspect the exact assets you synced.

```bash
# if synced directly into your repo
ls skills
ls instructions
ls tokens/themes
```

In this repository, the primary docs are:

- [Skills Catalog](reference/skills-catalog.md)
- [`.sheen.yml` Guide](guides/sheen-yml.md)
- [Adopting Tokens](guides/adopting-tokens.md)

Use these to map from business need to concrete assets:

- Need fast review workflows: start with a small skill subset
- Need governance language only: start with instruction layers
- Need design-system consistency: start with tokens and themes

## Step 5. Pick an integration mode and lock it in (2 minutes)

Choose one of the three profiles and commit that profile in `.sheen.yml`. You
can switch modes later without changing tooling, only configuration.

### Lean (solo or low overhead)

```yaml
source: https://github.com/IBuySpy-Shared/basecoat-sheen.git
ref: main
skills:
  - design-review
  - web-usability-review
instructions:
  - sheen-10-core-design-principles
```

### Token-only (design system, no AI assets)

```yaml
source: https://github.com/IBuySpy-Shared/basecoat-sheen.git
ref: main
skills: []
agents: []
instructions:
  - sheen-20-tokens-foundations
themes:
  - light
  - dark
  - high-contrast
```

### Full (cross-functional)

```yaml
source: https://github.com/IBuySpy-Shared/basecoat-sheen.git
ref: main
# Omit allow-lists to sync the full catalog
```

Profile details and expanded templates are documented in
[Adoption Modes](adoption-modes.md).

---

## What "good" looks like after day 1

By the end of day 1, a healthy onboarding should produce three outcomes in the
consumer repository:

1. **Config clarity:** `.sheen.yml` is committed, reviewed, and pinned to your
   chosen source/ref policy.
2. **Asset clarity:** the synced directories match your selected mode (Lean,
   Token-only, or Full), with no surprise payload.
3. **Workflow clarity:** one concrete team workflow is running with the new
   assets (for example: a design review, token audit, or standards check).

You can capture this in PR notes with a short block:

```text
Profile: Lean
Ref policy: main (temporary) -> tag pin planned next sprint
Assets verified: skills/, instructions/
First workflow: design-review applied to checkout flow
```

This simple record makes upgrades and future audits easier because reviewers can
trace why the initial scope was selected.

## Common first-week workflow

Use this sequence for the first week after onboarding:

1. Keep your initial profile small (Lean or Token-only)
2. Run one team workflow with synced assets
3. Add only the next missing assets in `.sheen.yml`
4. Re-sync and validate in CI
5. Record your selected profile in team docs

This prevents over-adoption while giving a clear path to full governance later.

## Example pull request flow

If you are introducing sheen to an established consumer repository, use a
single-purpose onboarding PR:

```bash
git checkout -b docs/onboard-sheen
cp .sheen.yml.example .sheen.yml
# edit .sheen.yml to chosen mode
./sync.sh   # or ./sync.ps1
git add .sheen.yml skills instructions tokens
git commit -m "Onboard basecoat-sheen in Lean mode"
```

PR description checklist:

- Selected adoption mode and reason
- Sync command used
- Directories added or updated
- Follow-up plan (expand mode or pin release tag)

This keeps onboarding transparent and lowers friction for teams reviewing design
governance changes for the first time.

## Troubleshooting quick hits

### Sync ran but expected assets are missing

Check whether allow-lists in `.sheen.yml` are too narrow, then re-sync.

```yaml
skills:
  - design-review
```

If only one skill is listed, only that skill is synced.

### Conflicts during sync

Resolve local merge conflicts in `.sheen.yml` first, then run sync again.
Treat `.sheen.yml` as a source-of-truth config file, not generated output.

### Already using basecoat

Keep both configurations:

```text
.basecoat.yml
.sheen.yml
```

Run your established sync workflow for each. Namespaces are intentionally
separate.

For expanded answers, use the [Onboarding FAQ](onboarding-faq.md).

## Where to go next

- Read [Adoption Modes](adoption-modes.md) to pick a stable rollout profile
- Check [Onboarding FAQ](onboarding-faq.md) for setup and maintenance answers
- Browse [Skills Catalog](reference/skills-catalog.md) for workflow capabilities
- Use [`.sheen.yml` Guide](guides/sheen-yml.md) for full config reference
- For token usage patterns, read [Adopting Tokens](guides/adopting-tokens.md)

When your team is ready, move from Lean or Token-only to Full by removing
allow-lists, pinning to a release tag, and syncing on a regular cadence.
