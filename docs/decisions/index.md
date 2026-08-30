# Design Decisions

Architecture Decision Records (ADRs) and design debate logs for basecoat-sheen.
Each document captures the problem, options considered, evaluation criteria, and the
chosen direction — so future contributors understand *why* the system is shaped the way it is.

## Log

| # | Title | Date | Status |
|---|-------|------|--------|
| [ADR-001](adr-001-sheen-router.md) | Sheen router: intents, vocabulary, skill & agent routing, factory patterns | 2026-08-16 | Accepted |
| [ADR-002](adr-002-intent-disambiguation.md) | Intent disambiguation strategy | 2026-08-16 | Accepted |
| [ADR-003](adr-003-diagram-static-by-default.md) | Documentation diagrams are static by default | 2026-08-30 | Accepted |
| [ADR-004](adr-004-diagram-taxonomy-discipline.md) | Diagram taxonomy: semantic pattern vs. layout type | 2026-08-30 | Accepted |
| [ADR-005](adr-005-diagram-skin-bridge.md) | Diagram skin is generated from DTCG tokens (bridge, not a second style guide) | 2026-08-30 | Accepted |
| [ADR-006](adr-006-diagram-scope.md) | Documentation diagram scope: included vs. excluded types | 2026-08-30 | Accepted |
| [AUDIT-001](spec-gap-audit-2026-08-16.md) | Spec gap audit — all specs vs implementation | 2026-08-16 | Published |

## Conventions

- One file per decision, named `adr-NNN-<slug>.md`.
- Status values: `Draft` → `Accepted` → `Superseded` (link to superseding ADR).
- When a decision is reversed, mark it `Superseded` and create a new ADR — never delete the old one.
