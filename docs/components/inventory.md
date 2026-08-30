# Component Inventory

A browsable index of the foundational components this design system expects
downstream consumers to spec and build — check here before drafting a new
`component-spec` entry, so teams reuse an existing spec (or its gap) instead
of silently duplicating one. This inventory is atoms/molecules; multi-component
compositions live in `docs/components/pattern-library.md` instead.

Maturity legend:

- **unspecified** — named and scoped, no `component-spec` written yet
- **draft** — a spec exists but hasn't been reviewed/adopted
- **stable** — spec reviewed, adopted, safe to build against
- **deprecated** — superseded; see replacement note

| Component | Maturity | Spec | Last reviewed |
|---|---|---|---|
| Button | unspecified | not yet authored | — |
| Icon button | unspecified | not yet authored | — |
| Text field (input) | unspecified | not yet authored | — |
| Textarea | unspecified | not yet authored | — |
| Select | unspecified | not yet authored | — |
| Checkbox | unspecified | not yet authored | — |
| Radio | unspecified | not yet authored | — |
| Switch / toggle | unspecified | not yet authored | — |
| Slider | unspecified | not yet authored | — |
| Badge / tag | unspecified | not yet authored | — |
| Avatar | unspecified | not yet authored | — |
| Link | unspecified | not yet authored | — |
| Divider | unspecified | not yet authored | — |
| Progress indicator / spinner | unspecified | not yet authored | — |
| Skeleton | unspecified | not yet authored | — |
| Alert / banner | unspecified | not yet authored | — |

## Workflow

1. Look up the component here before writing a new spec.
2. If it's listed as **unspecified** or **draft**, use `component-spec` to
   author or complete the spec, then update this row (maturity, spec link,
   last-reviewed date).
3. If it's **stable**, link to the existing spec instead of re-authoring one.
4. If it's **deprecated**, follow the replacement note rather than reviving it.
5. If the component you need isn't listed at all, confirm it's genuinely
   atomic (not a composition — see `pattern-library` first), then add a new
   row here as **unspecified** before spec'ing it.

## Drift prevention

This inventory exists to prevent the same failure mode as the pattern
catalog: multiple teams independently authoring incompatible specs for the
same component because there was no single place to check "does a spec
already exist for this." Keep every row's maturity and spec link current as
specs are authored — a stale inventory is worse than none.
