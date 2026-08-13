# basecoat-sheen — Specification Set

Detailed specifications for the assets and subsystems defined in the root
[`SPEC.md`](../SPEC.md). Each document below is normative for its area: it defines
the contract implementers must satisfy. No assets are implemented yet.

| # | Spec | Scope |
|---|---|---|
| 01 | [Token system](01-token-system.spec.md) | `tokens/` structure, DTCG schema, tiers, themes, build, validation |
| 02 | [Skill contract](02-skill-contract.spec.md) | `SKILL.md` frontmatter, body, `eval.yaml`, token budget |
| 03 | [Agent contract](03-agent-contract.spec.md) | `*.agent.md` structure, skill composition, evals |
| 04 | [Instruction layers](04-instruction-layers.spec.md) | `sheen-<NN>-<layer>-` numbering, scoping, precedence |
| 05 | [Validation & checks](05-validation-checks.spec.md) | `checks.json`, `sheen-metadata.json`, CI gates |
| 06 | [Consumption & sync](06-consumption-sync.spec.md) | `.sheen.yml`, `sync.*`, `rollback.*` |
| 07 | [Skill catalog](07-skill-catalog.spec.md) | Per-skill spec for every skill in the catalog |
| 08 | [Standards & conformance](08-standards-conformance.spec.md) | WCAG/W3C, ISO, OWASP + i18n/privacy mapped to enforcing assets |

## Conventions used in these specs

- **MUST / SHOULD / MAY** follow RFC 2119 meaning.
- File paths are relative to the repository root.
- "Consumer" = a repository that syncs sheen assets in. "Source" = this repo.
- Every asset name is kebab-case and stable once published (renames are breaking).

## Status

Draft v0.1 — tracks root `SPEC.md` §1–§13. Update this set and the root spec
together; a `checks.json` drift rule (see spec 05) fails CI if the catalog and
these specs disagree.
