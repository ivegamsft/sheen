# Contributing to basecoat-sheen

Thanks for helping build the design/UX finish coat. This guide covers how to add
and change assets so they pass validation and stay consistent with the spec.

## Ground rules

1. **Spec first.** The root [`SPEC.md`](SPEC.md) and [`specs/`](specs/) are
   normative. Update the relevant spec in the *same* change as the asset — a
   `checks.json` drift rule fails CI when the catalog and specs disagree
   (see [`specs/05-validation-checks.spec.md`](specs/05-validation-checks.spec.md)).
2. **Never edit `vendor/`.** The vendored basecoat tree is read-only and validated
   upstream. Changes to basecoat belong in the basecoat repo; refresh the vendored
   copy by re-pinning (see [`vendor/basecoat/VENDOR.md`](vendor/basecoat/VENDOR.md)).
3. **Namespaces.** sheen assets use the `sheen-*` prefix; never reuse a
   `basecoat-*` name. Asset names are kebab-case and **stable once published** —
   renames are breaking (major version bump + CHANGELOG migration note).
4. **Least privilege.** Skills/agents declare `allowed-tools` narrowly; keep it
   empty unless a tool is genuinely required.

## Authoring assets

| Asset | Contract | Lives in |
|---|---|---|
| Skill | [`specs/02-skill-contract.spec.md`](specs/02-skill-contract.spec.md) | `skills/<name>/` (`SKILL.md` + `eval.yaml`) |
| Agent | [`specs/03-agent-contract.spec.md`](specs/03-agent-contract.spec.md) | `agents/*.agent.md` |
| Instruction | [`specs/04-instruction-layers.spec.md`](specs/04-instruction-layers.spec.md) | `instructions/sheen-<NN>-<layer>-<topic>.instructions.md` |
| Token | [`specs/01-token-system.spec.md`](specs/01-token-system.spec.md) | `tokens/{core,semantic,themes}/` (DTCG JSON) |

Every skill `description` MUST carry `USE FOR:` (≥3 triggers) and `DO NOT USE FOR:`
(≥2 anti-triggers), and every `eval.yaml` MUST have ≥3 positive and ≥2 negative
routing scenarios.

## Validating locally

Validation is designed to run identically locally and in CI. Until the `scripts/`
validators land (later phases), the CI `lint-and-validate` job in
[`.github/workflows/ci.yml`](.github/workflows/ci.yml) enforces the structural
rules (SKILL.md presence, name-matches-folder, agent frontmatter, instruction
naming, catalog integrity). Run the same checks by pushing a PR, or invoke the
validators once they exist:

```text
scripts/lint-frontmatter     # frontmatter, name match, description triggers, references
scripts/validate-tokens      # DTCG schema, references, naming, WCAG contrast
scripts/build-metadata       # regenerates sheen-metadata.json (never hand-edit)
```

## Pull requests

- Open a PR against `main` — direct pushes are rejected by enterprise rulesets.
- Pin any GitHub Action to a full-length commit SHA (`@v4` tags are rejected).
- All enterprise checks (CodeQL, code quality, Copilot review) must pass; there is
  no admin/self bypass. A maintainer may merge their own PR **after** checks pass.
- Keep changes scoped and the spec in sync. See [`.github/PROFILE.md`](.github/PROFILE.md)
  for the full governance model.

## Commit style

Write imperative, present-tense subjects (e.g. "Add color-system skill"). Group a
spec change and its asset change in one commit where practical.
