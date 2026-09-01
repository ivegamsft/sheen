# ADR-009 — Copilot Instructions Are Scoped to Design and UI Surfaces

| Field | Value |
|---|---|
| **Date** | 2026-08-31 |
| **Status** | Accepted |
| **Deciders** | sheen maintainers |
| **Supersedes** | Instruction-layer universal-scope guidance in spec 04 |
| **Superseded by** | — |

## Context

Nine of sheen's ten Copilot instruction files used `applyTo: "**/*"`.
Consequently, a downstream consumer loaded approximately 9,778 tokens of
design-system guidance while editing unrelated backend, infrastructure, and
database files. In repositories consuming both basecoat and sheen, that cost
stacked with the engineering instruction set on every request.

Sheen governs design and UX surfaces. WCAG component guidance, brand voice,
navigation rules, and localization constraints are valuable when Copilot is
working on UI code, design assets, or user-facing documentation, but add noise
to a C# service, Bicep template, SQL migration, or backend-only TypeScript file.

GitHub Copilot path-specific instructions support comma-separated glob patterns
in the `applyTo` frontmatter field. This allows each instruction layer to retain
automatic application without making every layer repository-wide.

## Options Considered

### Option 1 — Retain universal scopes

- ✅ No risk of missing guidance on an unusual frontend path.
- ❌ Charges every non-design task approximately 9.8k irrelevant tokens.
- ❌ Lowers signal by injecting guidance that cannot affect the edited file.

#### Score: 2/10

### Option 2 — Use one shared frontend extension list for all instructions

- ✅ Simple to explain and validate.
- ✅ Removes guidance from common backend, IaC, and data extensions.
- ❌ Loads taxonomy, localization, navigation, and component rules together even
  when only one domain is relevant.
- ❌ Cannot cover design-system metadata and locale directories without making
  the shared list broad again.

#### Score: 6/10

### Option 3 — Give each instruction a domain-specific surface scope *(chosen)*

Use supported comma-separated patterns. Core design/accessibility and standards
cover broad UI/design surfaces; specialized layers additionally target only
their relevant component, navigation, catalog, token, asset, or localization
paths.

- ✅ Non-design backend/IaC/data edits load no sheen instructions.
- ✅ UI/design edits retain the complete set of relevant layers.
- ✅ Specialized guidance appears only where it can affect the result.
- ❌ New or unconventional frontend paths may require extending a scope.
  Contract tests and the normative spec make that maintenance explicit.

#### Score: 9/10

### Option 4 — Convert all nine instructions to on-demand skills

- ✅ Zero ambient token cost.
- ❌ Removes automatic guardrails from ordinary UI implementation.
- ❌ Relies on users or agents remembering to invoke every relevant review skill.

#### Score: 4/10

## Decision

**Adopt Option 3.** Universal `**` and `**/*` scopes are prohibited for sheen
instructions. Each instruction must declare comma-separated GitHub Copilot glob
patterns for the files and directories where its guidance is actionable.

Full audits remain on-demand skills. Instructions continue to provide ambient
guardrails during implementation, but only on matching design/UI surfaces.

`scripts/test-instruction-scopes.ps1` enforces the boundary with representative
positive cases and proves that backend C#/TypeScript/JavaScript, Bicep, and SQL
paths match none of the nine formerly universal layers.

## Consequences

- **Positive:** Representative non-design edits reclaim approximately 9.8k
  instruction tokens per request.
- **Positive:** UI and design work receives higher-signal, domain-relevant
  guidance.
- **Positive:** The scope boundary is executable in CI instead of relying on
  frontmatter review.
- **Positive:** The token instruction now covers both source `tokens/**` and
  downstream `sheen/tokens/**` locations.
- **Risk:** A consumer using an unconventional frontend directory or extension
  may not match every expected layer. Add the narrowest missing pattern and a
  positive contract case rather than restoring a universal scope.
- **Constraint:** Use comma-separated patterns documented by GitHub Copilot;
  do not rely on brace expansion.

## Related

- Issue #155
- `specs/04-instruction-layers.spec.md`
- `scripts/test-instruction-scopes.ps1`
- `instructions/*.instructions.md`
