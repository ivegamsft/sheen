# basecoat-sheen

**The design/UX "finish coat" for [basecoat](https://github.com/IBuySpy-Shared/basecoat).**

basecoat-sheen is a shared repository of GitHub Copilot customizations — skills,
agents, instructions, prompts, and a validated design-token system — focused on
**design, UX, accessibility, and brand**. It sits on top of the engineering-SDLC
foundation that basecoat provides: basecoat governs the *engineering* surface,
sheen governs the *design* surface, and the two namespaces (`basecoat-*` /
`sheen-*`) never collide, so a consumer can adopt both together.

> **Status:** Scaffold (Phase 0). The contract is specified in [`SPEC.md`](SPEC.md)
> and [`specs/`](specs/); assets land phase-by-phase (see
> [Delivery phases](SPEC.md#11-delivery-phases)). Directories are seeded empty and
> CI no-ops gracefully until assets exist.

---

## What's here

| Path | Contents |
|---|---|
| [`SPEC.md`](SPEC.md) | Root specification (§1–§13): vision, structure, tokens, catalog, phases, decisions |
| [`specs/`](specs/) | Normative per-area specs (tokens, skill/agent/instruction contracts, validation, sync, catalog, conformance) |
| `tokens/` | DTCG/W3C design tokens — `core/` (global primitives), `semantic/` (alias roles + states), `themes/` (light/dark/high-contrast) |
| `skills/` | sheen-authored Copilot skills (flat `<name>/` folders: `SKILL.md`, `eval.yaml`) |
| `agents/` | sheen agents (`*.agent.md`) |
| `instructions/` | Layered `sheen-<NN>-<layer>-<topic>.instructions.md` |
| `prompts/` · `templates/` | Prompt starters and shared cross-skill templates |
| [`vendor/basecoat/`](vendor/basecoat/) | Pinned, **read-only** copy of basecoat's asset library + tooling (see [`VENDOR.md`](vendor/basecoat/VENDOR.md)) |

## Consuming sheen

A consumer repository pulls selected assets in with a small config file and the
sync script. See [`specs/06-consumption-sync.spec.md`](specs/06-consumption-sync.spec.md)
for the full contract.

1. Copy [`.sheen.yml.example`](.sheen.yml.example) to `.sheen.yml` in your repo and
   set `source`, `ref`, and any asset allow-lists.
2. Run the sync entry point:

   ```powershell
   # Windows PowerShell
   $env:SHEEN_REPO = 'https://github.com/IBuySpy-Shared/basecoat-sheen.git'; .\sync.ps1
   ```

   ```bash
   # macOS / Linux
   SHEEN_REPO=https://github.com/IBuySpy-Shared/basecoat-sheen.git ./sync.sh
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
