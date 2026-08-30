# ADR-007 — Populated Catalogs Prevent Spec Drift (Component Inventory & UI Pattern Catalog)

| Field | Value |
|---|---|
| **Date** | 2026-08-30 |
| **Status** | Accepted |
| **Deciders** | sheen maintainers |
| **Supersedes** | — |
| **Superseded by** | — |

## Context

An audit comparing sheen's design-system governance surface against
published design-system best practice (see `docs/design-context.md`
cross-references and issues #140, #141) found two contract-only gaps:

1. **`pattern-library` skill** defined the *rules* for authoring a UI design
   pattern (loading states, empty states, error states, form validation,
   etc.) but shipped with no populated catalog of the patterns themselves —
   every team had to author its own from scratch.
2. **`component-spec` skill** defined the *contract* a component spec must
   satisfy but had no inventory of which foundational components (Button,
   Text field, Select, …) already exist, are in draft, or are still
   unspecified — nothing prevented two teams from independently spec'ing the
   same atom with incompatible contracts.

Both gaps share the same failure mode: a contract-only skill with no
single source of truth for "has this already been done, and if so, where."
Multiple downstream teams hitting the same gap independently converge on
incompatible answers, which is exactly the drift sheen exists to prevent.

## Options Considered

### Option 1 — Leave both skills contract-only; let each consumer populate its own catalog
Consumers author their own pattern/component catalogs locally after
adopting the skill.

- ✅ No upstream maintenance burden
- ❌ Reproduces the exact drift problem sheen is designed to solve —
  every consumer reinvents the same 10-16 foundational answers
- ❌ No shared vocabulary for "is Button spec'd yet" across teams

**Score: 2/10**

### Option 2 — Populate both catalogs upstream in sheen *(chosen)*
Ship `docs/components/inventory.md` (16-row atoms/molecules table: maturity,
spec link, last-reviewed) and a populated pattern catalog in
`pattern-library`, both checked *before* authoring a new spec, both updated
as part of the same workflow that authors a spec.

- ✅ Single upstream source of truth; consumers check-before-build instead of
  reinventing
- ✅ Explicit maturity states (`unspecified` → `draft` → `stable` →
  `deprecated`) make partial progress visible instead of a binary
  done/not-done
- ✅ Compositions (`pattern-library`) are kept explicitly separate from
  atoms/molecules (`component-spec`/inventory) — a pattern like "empty state"
  is a composition of components, not a component itself, so conflating the
  two catalogs would blur the contract each skill enforces
- ❌ Upstream maintenance burden: catalogs must be kept current as new specs
  land, or the inventory itself becomes a second source of drift

**Score: 9/10**

### Option 3 — Merge both catalogs into a single document
One combined "everything" catalog covering atoms, molecules, and
compositions.

- ✅ One file to check instead of two
- ❌ Conflates two different contracts (`component-spec` vs
  `pattern-library`) that intentionally have different authoring rules —
  a composition references components, it does not redefine them
- ❌ Harder to keep the maturity legend meaningful across two different
  kinds of artifact

**Score: 4/10**

## Decision

**Adopt Option 2.** Ship a populated, maturity-tracked component inventory
(`docs/components/inventory.md`, issue #141) and a populated UI pattern
catalog (`pattern-library` skill, issue #140), kept as two separate
catalogs because they enforce two separate contracts (atom/molecule spec vs.
multi-component composition pattern). Both skills' workflows now require
checking the relevant catalog first and updating it as the last step of
authoring or revising a spec/pattern.

## Consequences

- **Positive:** `component-spec` and `pattern-library` now have an explicit
  drift-prevention step baked into their workflow sections, not just their
  output contracts.
- **Positive:** Maturity legend (`unspecified`/`draft`/`stable`/`deprecated`)
  gives partial progress a name, instead of forcing a premature "done" claim.
- **Risk:** A stale inventory is worse than none — if a row's maturity/spec
  link isn't updated when a spec changes, downstream teams will trust a
  catalog that is now wrong. This is the same risk this ADR exists to
  prevent, just moved upstream; CI does not currently gate on inventory
  freshness (no automated check exists yet), so this remains a manual
  discipline enforced by skill workflow steps rather than a hard gate.

## Related

- `docs/components/inventory.md`, `docs/components/index.md`,
  `docs/components/component-spec.md`
- `skills/component-spec/SKILL.md`, `skills/pattern-library/SKILL.md`
- Issues #140 (UI pattern catalog), #141 (component inventory)
