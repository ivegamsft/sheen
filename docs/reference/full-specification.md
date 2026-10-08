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

## Guide authoring and HTML delivery

[Spec 14: Guide Authoring and HTML Delivery](https://github.com/ivegamsft/sheen/blob/main/specs/14-html-brand-guide.spec.md)
extends the existing `style-guide-authoring` skill, not a new skill. It retains
Markdown and governance-only requests while adding approved-input HTML authoring,
bounded offline packaging, safe refresh and read-only freshness assessment. It
reuses existing guide templates and downstream evidence with explicit source
precedence and approval states, keeping structural references separate from
permitted output inputs.

The implementation is delivered through the existing skill name with a
skill-local renderer and freshness helpers. Evidence is split across canonical
input/freshness tests, HTML packaging/browser checks, and synced consumer
complete-folder execution; see [Style Guide Authoring](../guides/style-guide-authoring.md).
It does not publish a guide, update guide URLs, import a reference's identity,
assets, values, wording or metadata, or approve downstream brand decisions.
