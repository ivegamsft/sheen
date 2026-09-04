# Experience Blueprint Contract Check Fixtures

`valid-sample.json` and `invalid-sample.json` are used by
`scripts/audit-experience-blueprint.ps1` and CI (see `.github/workflows/ci.yml`)
to prove the contract checks in `specs/10-experience-blueprint.spec.md` §12
actually catch violations, mirroring the diagram anti-slop fixture pattern
(`tests/fixtures/diagrams/clean-sample.svg` / `broken-sample.svg`).

This JSON shape is **one illustrative example representation**, not a
mandated schema (spec §4). A downstream may represent its blueprint in any
format — Markdown, YAML, a database, or a design tool — as long as it
preserves the same concepts, identifiers, and relationships.

- `valid-sample.json` — a small commerce-archetype blueprint (audit mode)
  that passes with zero findings: unique IDs, every page resolves its
  layout, every flow step resolves to a page, the flow declares recovery and
  cancellation, every page has all required states or `not-applicable`,
  every responsive page declares breakpoints, the one finding cites valid
  evidence and artifact IDs, and the summary cites its sources.
- `invalid-sample.json` — the same shape with deliberate violations of each
  rule above, used to prove the checker fails on real breakage.
