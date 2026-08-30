---
name: pattern-library
compatibility: [github-copilot-cli]
description: "Use when documenting, cataloging, or composing reusable design patterns into a shared pattern library. USE FOR: pattern documentation, pattern composition guidance, pattern index authoring, choosing a proven UI pattern (modal, tabs, accordion, card, breadcrumb, dropdown, tooltip, toast, stepper, data table, command palette, empty state). DO NOT USE FOR: single component deep specs, token schema validation."
category: design
metadata:
  category: design
  maturity: stable
  audience: [designer, developer]
  pillar: components
allowed-tools: []
---

# pattern-library

Document reusable multi-component UI patterns and select the right proven
pattern instead of inventing a bespoke interaction.

## Catalog

See `docs/components/pattern-library.md` for the full catalog: Modal/Dialog,
Tabs, Accordion, Card, Breadcrumbs, Dropdown/Menu, Tooltip/Popover,
Toast/Notification, Stepper/Wizard, Data Table, Command Palette, Empty State.
Each entry has intent, when-to-use, composition, and anti-patterns.

## Workflow

1. Check the catalog first — match the user's scenario to an existing pattern
   before proposing a new one.
2. If an existing pattern fits: specify its composition using `component-spec`
   for each constituent component, and confirm the states via
   `ui-states-interaction`.
3. If no pattern fits: define scenario and intent, propose a composition map,
   and document constraints/anti-patterns using the same catalog entry shape.
4. Validate the pattern against adjacent standards (a11y model, responsive
   behavior) and flag any drift from an existing catalog entry.
5. Add net-new patterns to the catalog (not as one-off product documentation)
   so the next team reuses rather than reinvents it.

## Guardrails

- Stay within explicit skill scope — a single component belongs in
  `component-spec`, not here.
- Do not invent a new pattern when an existing catalog entry already solves
  the scenario; cite the anti-pattern guidance instead.
- Avoid unsupported quality/compliance claims.
- Avoid duplicate ownership with neighboring skills.

## Output

- Pattern catalog entry or reference to an existing one, with composition map
  and anti-patterns.

## Delegates / pairs with

- component-spec
- ui-states-interaction
- style-guide-authoring
