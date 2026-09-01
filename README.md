# basecoat-sheen

**The design/UX "finish coat" for [basecoat](https://github.com/ivegamsft/sheen).**

basecoat-sheen is a shared repository of GitHub Copilot customizations — skills,
agents, instructions, prompts, and a validated design-token system — focused on
**design, UX, accessibility, and brand**. It sits on top of the engineering-SDLC
foundation that basecoat provides: basecoat governs the *engineering* surface,
sheen governs the *design* surface, and the two namespaces (`basecoat-*` /
`sheen-*`) never collide, so a consumer can adopt both together.

> **Status:** v0.11.0 release — 58 skills, 6 agents, 10 instruction layers, and
> 10 templates, all validated against [`checks.json`](checks.json) in CI. The
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

Sync is **idempotent** and records a manifest so [`rollback.ps1`](rollback.ps1) /
[`rollback.sh`](rollback.sh) can revert precisely.

## Governance & vocabulary

- [`.lexicon.md`](.lexicon.md) — the canonical design vocabulary used across assets.
- [`docs/design-context.md`](docs/design-context.md) — the design values and
  influence sources sheen appeals to in reviews.
- Validation rules live in [`checks.json`](checks.json) and are enforced in CI
  (see [`specs/05-validation-checks.spec.md`](specs/05-validation-checks.spec.md)).
  `vendor/` is never scanned — it is validated upstream.

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
