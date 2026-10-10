# basecoat-sheen

**The design/UX "finish coat" for [basecoat](https://github.com/ivegamsft/sheen).**

basecoat-sheen is a shared repository of GitHub Copilot customizations — skills,
agents, instructions, prompts, and a validated design-token system — focused on
**design, UX, accessibility, and brand**. It sits on top of the engineering-SDLC
foundation that basecoat provides: basecoat governs the *engineering* surface,
sheen governs the *design* surface, and the two namespaces (`basecoat-*` /
`sheen-*`) never collide, so a consumer can adopt both together.

> **Status:** v1.1.0 release — 61 skills, 7 agents, 10 instruction layers, and
> 18 templates, all validated against [`checks.json`](checks.json) in CI. The
> contract is specified in [`SPEC.md`](SPEC.md) and [`specs/`](specs/); see
> [`CHANGELOG.md`](CHANGELOG.md) for release history.

---

## What's here

| Path | Contents |
|---|---|
| [`SPEC.md`](SPEC.md) | Root specification (§1–§13): vision, structure, tokens, catalog, phases, decisions |
| [`specs/`](specs/) | Normative per-area specs (tokens, skill/agent/instruction contracts, validation, sync, catalog, conformance) |
| `tokens/` | DTCG/W3C design tokens — `core/` (global primitives), `semantic/` (alias roles + states), `themes/` (light/dark/high-contrast) |
| `skills/` | sheen-authored Copilot skills (flat `<name>/` folders: `SKILL.md`, `eval.yaml`) |
| `agents/` | sheen agents (`*.agent.md`) |
| `instructions/` | Path-scoped `sheen-<NN>-<layer>-<topic>.instructions.md` guidance for design/UI surfaces |
| `prompts/` · `templates/` | Prompt starters and shared cross-skill templates |
| [`vendor/basecoat/`](vendor/basecoat/) | Pinned, **read-only** copy of basecoat's asset library + tooling (see [`VENDOR.md`](vendor/basecoat/VENDOR.md)) |

## Consuming sheen

A consumer repository pulls selected assets in with a small config file and the
sync script. See [`specs/06-consumption-sync.spec.md`](specs/06-consumption-sync.spec.md)
for the full contract.

### ⚡ Getting started in 60 seconds

Run the bootstrap script **from inside your repo** — it downloads the sync
scripts, creates a starter `.sheen.yml`, and runs the initial sync in one step:

```powershell
# Windows / PowerShell
pwsh -c "iex (iwr https://raw.githubusercontent.com/ivegamsft/sheen/main/bootstrap.ps1).Content"
```

```bash
# macOS / Linux
bash <(curl -fsSL https://raw.githubusercontent.com/ivegamsft/sheen/main/bootstrap.sh)
```

After the sync completes:

1. **Commit** the result: `git add .sheen.yml .sheen/manifest.json .github/ sheen/`
2. **Reset Copilot context** (required for skills to appear — see [context reset guide](docs/guides/consumer-lifecycle.md#resetting-copilot-context)):
   - CLI: `exit` then `gh copilot`
   - VS Code: `Ctrl+Shift+P` → **Developer: Reload Window**
   - JetBrains: restart editor
3. **Type `/`** in Copilot Chat and confirm `sheen-onboard` appears in the picker.

> ⚠️ **Common mistake:** `/sheen-onboard` is a skill that lives in `.github/skills/`.
> It does **not** exist until after the bootstrap sync completes and Copilot context
> is reset. Running bootstrap first is the only required prerequisite.

### Manual setup (advanced)

1. Copy [`.sheen.yml.example`](.sheen.yml.example) to `.sheen.yml` in your repo and
   set `source`, `ref`, and any asset allow-lists.
2. Download and run the sync entry point:

   ```powershell
   # Windows PowerShell — download then run
   Invoke-WebRequest https://raw.githubusercontent.com/ivegamsft/sheen/main/sync.ps1 -OutFile sync.ps1
   pwsh sync.ps1
   ```

   ```bash
   # macOS / Linux
   curl -fsSL https://raw.githubusercontent.com/ivegamsft/sheen/main/sync.sh -o sync.sh
   bash sync.sh
   ```

On Windows, `sync.ps1` stages its source checkout under
`%SystemDrive%\_sheen-sync` to avoid deep user-temp paths. If that location is not
writable, set `$env:SHEEN_SYNC_TEMP_ROOT` to another writable short path before
running the script.

Sync is **idempotent** and records a manifest so [`rollback.ps1`](rollback.ps1) /
[`rollback.sh`](rollback.sh) can revert precisely.

**Sync order:** run BaseCoat first, then Sheen last after every full refresh;
BaseCoat replaces shared `.github` paths even when asset names differ.

**Agent channel:** agents default to organization discovery, not repository
copies. The `ivegamsft` channel is `.github-private/agents/`; other
organizations must publish their own central channel before migrating, or set
`agent_distribution: repository` for explicit compatibility on supported hosts.
The `agents` allow-list applies only in repository mode. Migration removes only
verified previous manifest-owned copies and blocks on modified/unverifiable files.

**Scheduled updates:** set `install_sync_workflow: true` to install/update
`.github/workflows/sheen-sync.yml`. With the default false, an existing managed
workflow is preserved without updates. To disable its schedule, delete it and
keep opt-in off; later syncs will not recreate it.

Source release publication opens a governed central-channel PR and records
pinned provenance/hashes. Automation requires `SHEEN_ORG_AGENTS_TOKEN`, scoped
to Contents and Pull requests read/write on the central repository only; it
must not have an enterprise-owner bypass. Merge publication PRs through normal
gates before treating a release's agents as delivered. Roll back through a
central revert PR and restore the consumer's previous pinned ref if necessary.

## Wireframe exploration

Use `wireframing` to draft screen specifications, sketched SVG boards or explicitly
requested offline HTML click-throughs. The [portable skill contract](skills/wireframing/references/artifact-contract.md)
includes a complete task-flow sample and optional dependency-free Python renderer.
Screens retain page/state/flow IDs; prototypes simulate interactions only and
must pass visual/task review before production handoff to `design-to-code`.

## Governance & vocabulary

- [`.lexicon.md`](.lexicon.md) — the canonical design vocabulary used across assets.
- [`docs/design-context.md`](docs/design-context.md) — the design values and
  influence sources sheen appeals to in reviews.
- Validation rules live in [`checks.json`](checks.json) and are enforced in CI
  (see [`specs/05-validation-checks.spec.md`](specs/05-validation-checks.spec.md)).
  `vendor/` is never scanned — it is validated upstream.

## Platform interfaces

Sheen is the design-system and UX governance product in the AI-SDLC governance
family. Contracts are defined in
[`basecoat-api-spec`](https://github.com/ivegamsft/sheen-api-spec) and
[`basecoat-mcp-spec`](https://github.com/ivegamsft/sheen-mcp-spec);
shared IDs and schemas come from Binder. Sheen stays Git-native: the synced
assets in this repository remain the source of truth, and the API is a read
adapter over them.

| Interface | Direction |
| --- | --- |
| Authorization | Tokens, vocabulary, and design rules are readable by family products and consumers; changes follow PR review in this repository. |
| API | Design tokens and design-rule catalog, including `checks.json` validation rules and `.lexicon.md` vocabulary, by release version. |
| MCP | Read-only: `get_tokens`, `list_design_rules`, `explain_design_rule`. |
| Integrated graph | Contributes design-system release and rule nodes; Batchbook records which apps have adopted which versions. |

These are initial directions, not approved contracts.

## Contributing

See [`CONTRIBUTING.md`](CONTRIBUTING.md). This repo runs on a shared enterprise EMU
instance; enterprise/org rulesets are the authoritative merge governance
(PR-required, CodeQL + code quality, Copilot review, SHA-pinned actions). See
[`.github/PROFILE.md`](.github/PROFILE.md).

## License

To be finalized (defaults to matching basecoat — tracked as decision **D5** in
[`SPEC.md` §13](SPEC.md#13-open-decisions)).

Third-party attribution for design guidance and rule sets adapted from
external projects (e.g. the diagram-design integration under epic #110) is
tracked in [`THIRD_PARTY_LICENSES.md`](THIRD_PARTY_LICENSES.md).
