# Worked example: auditing an app's existing component usage

> Representative scenario for the `app-component-catalog` skill's audit mode
> (spec 11 §9). Fictional sample app: a mid-size internal operations console.

## Scope and inputs

- Design system: the app's own accepted token/component documentation.
- Evidence: three implementation bindings observed in the repo —
  `PrimaryCTA`, `ButtonSolid`, and `ActionButton` — plus their usages across
  12 pages.
- Experience Blueprint: task pages for "approve request," "submit form," and
  "export report."

## Step-by-step reasoning

1. **Inventory** — `PrimaryCTA` (8 usages), `ButtonSolid` (3 usages),
   `ActionButton` (1 usage, added last sprint) are all rendered as a filled,
   high-emphasis, single-action control.
2. **Group by purpose/semantics, not name** — all three trigger a single
   primary user action, carry the same emphasis, and appear in the same
   region roles (page header action, form footer, confirmation dialog).
   Evidence supports one logical component, not three.
3. **Alias vs. drift** — `ButtonSolid` and `ActionButton` differ from
   `PrimaryCTA` only in border-radius and one hard-coded color value with no
   documented variant rule behind them. Classification: **implementation
   drift**, not a legitimate variant.
4. **Composition/placement check** — one `ActionButton` usage appears nested
   inside another `ActionButton` (in a review-summary card). No adjacency
   rule permits this; flagged as misuse.
5. **Missing states** — none of the three bindings implement a loading state
   for the "submit form" flow, where the action calls a slow network
   operation. Flagged as a missing-state gap with user impact (double
   submission risk).

## Recorded finding (sample)

- **Logical component:** `Primary Action` (canonical name chosen by the app
  team) — aliases: `PrimaryCTA`, `ButtonSolid`, `ActionButton`.
- **Classification:** one logical component; two bindings show
  implementation drift and should converge on the canonical binding.
- **Evidence:** 12 page usages, 3 distinct bindings, 1 nested-usage misuse,
  1 missing loading state.
- **Confidence:** high (behavioral and placement evidence agree).
- **Impact:** medium — inconsistent visual weight across pages, one
  accessibility/state gap with user-facing risk (double submission).
- **Affected pages:** approve request, submit form, export report.
- **Recommended catalog action:** normalize to one canonical entry using
  `templates/app-component-catalog/component-entry.md`; add the missing
  loading state to §7; remove the nested-usage misuse; deprecate the two
  drifted bindings once the canonical one is adopted.
