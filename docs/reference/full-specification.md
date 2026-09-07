# Full Specification

`SPEC.md` and the files under `specs/` are the normative source of truth for the
repository. Use this page as the map, then read the source files directly for
exact rules.

## Read first

- [SPEC.md](https://github.com/ivegamsft/sheen/blob/main/SPEC.md)
- [`specs/`](https://github.com/ivegamsft/sheen/tree/main/specs)

## Use this page for

- finding the right spec family quickly
- understanding how the docs site relates to the normative repo artifacts
- linking from consumer guidance back to the canonical source

## Reminder

If a docs page conflicts with the spec, the spec wins.

## Implemented theme lifecycle contracts

[Spec 13: App-Specific Theme Lifecycle](https://github.com/ivegamsft/sheen/blob/main/specs/13-theme-lifecycle.spec.md)
defines comparable previews, scoped selection records, readiness/impact
review, and custom-theme reuse and revision. It extends existing skills
without prescribing downstream tooling or shipping a preset collection.
The existing theming skill implements the shared records and decision rules;
[downstream guidance](../guides/theme-lifecycle.md) explains supported and blocked
paths and the illustrative T01-T14 checks. Review/closeout is tracked by
[epic #190](https://github.com/ivegamsft/sheen/issues/190).
This is agent-contract capability, not a product deployment or proof of
downstream rendered visual quality.
