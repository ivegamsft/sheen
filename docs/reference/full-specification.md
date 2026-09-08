# Full Specification

`SPEC.md` and the files under `specs/` are the normative source of truth for the
repository. Use this page as the map, then read the source files directly for
exact rules.

## Read first

- [SPEC.md](https://github.com/IBuySpy-Shared/basecoat-sheen/blob/main/SPEC.md)
- [`specs/`](https://github.com/IBuySpy-Shared/basecoat-sheen/tree/main/specs)

## Use this page for

- finding the right spec family quickly
- understanding how the docs site relates to the normative repo artifacts
- linking from consumer guidance back to the canonical source

## Reminder

If a docs page conflicts with the spec, the spec wins.

## Implemented theme lifecycle contracts

[Spec 13: App-Specific Theme Lifecycle](https://github.com/IBuySpy-Shared/basecoat-sheen/blob/main/specs/13-theme-lifecycle.spec.md)
defines comparable previews, scoped selection records, readiness/impact
review, and custom-theme reuse and revision. It extends existing skills
without prescribing downstream tooling or shipping a preset collection.
The existing theming skill implements the shared records and decision rules;
[downstream guidance](../guides/theme-lifecycle.md) explains supported and blocked
paths and the illustrative T01-T14 checks. Review/closeout is tracked by
[epic #190](https://github.com/IBuySpy-Shared/basecoat-sheen/issues/190).
This is agent-contract capability, not a product deployment or proof of
downstream rendered visual quality.

## Proposed HTML guide authoring

[Spec 14: HTML Brand Guide](https://github.com/IBuySpy-Shared/basecoat-sheen/blob/main/specs/14-html-brand-guide.spec.md)
specifies a proposed `brand-guide-html` skill for template, approved-input
generation and refresh modes. It composes existing specialists into an offline,
responsive reference guide with reusable sections, explicit evidence states and
strict separation between structural references and permitted output inputs.

This is a specification, not an available skill, renderer or publishing service.
It does not import a reference's identity, assets, values, wording or metadata.
Implementation and live catalog registration require separate authorization.
