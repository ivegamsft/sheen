# App Layout Catalog Templates

> Use these templates when running the `app-layout-catalog` skill. Copy them
> into the consumer repo's chosen location for its layout gallery (e.g.
> `docs/layouts/<layout-id>.md`) and populate every section — do not ship a
> layout entry with placeholder text remaining.

## Files

- `layout-catalog-entry.md` — one logical layout catalog entry covering every
  metadata area in `specs/12-app-layout-catalog.spec.md` §6 (identity, usage
  rules, IA/navigation applicability, region model, component placement,
  styling abstractions, data/content requirements, responsive behavior,
  accessibility structure, selection metadata, provenance).
- `audit-finding.md` — one audit-mode finding record for variant-vs-drift
  classification, page-to-layout mapping, and remediation prioritization
  (spec §8).

## How to use

1. Run the `app-layout-catalog` skill in audit or generate mode.
2. For each accepted logical layout, copy `layout-catalog-entry.md` and
   complete every section — leave nothing implementation-specific (no
   framework, grid, or DOM references) in the logical fields; put those only
   under "Implementation bindings (optional)".
3. For each audit observation, copy `audit-finding.md` and record evidence,
   confidence, user impact, and the recommended catalog action.
4. Add both to the app-specific gallery in the downstream's chosen
   representation (docs page, design-tool library, code catalog, etc.).
