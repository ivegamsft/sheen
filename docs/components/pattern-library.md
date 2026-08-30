# Pattern Library

Patterns are multi-component compositions (forms, tables, wizards, navigation
blocks). Each pattern entry should include:

- scenario and intent
- composition map
- constraints and anti-patterns
- accessibility and usability notes

## Catalog

These are the proven, reusable UI patterns most products need. Reach for one of
these before inventing a bespoke interaction — familiarity reduces user
cognitive load and prevents component drift (three teams building three
different "cards"). Each entry follows the same shape as `component-spec.md`:
intent, when to use, composition, and anti-patterns.

### Modal / Dialog

- **Intent**: interrupt the current flow for a focused, blocking decision or
  input.
- **When to use**: destructive-action confirmation, short focused forms,
  content that must be acknowledged before continuing.
- **Composition**: scrim + `component-spec` dialog + focus trap + close
  affordance (Esc, backdrop click, explicit button).
- **Anti-patterns**: stacking modals on modals; using a modal for content that
  belongs on its own page/route; blocking on a modal for non-critical info
  (use a toast/inline message instead).

### Tabs

- **Intent**: let users switch between sibling views of related content
  without navigating away.
- **When to use**: 2-7 mutually exclusive views at the same hierarchy level
  (e.g. "Overview / Activity / Settings").
- **Composition**: tab list (`role="tablist"`) + panels, one visible at a time,
  arrow-key roving focus per WAI-ARIA APG.
- **Anti-patterns**: using tabs for sequential/wizard steps (use Stepper
  instead); more than ~7 tabs (use a dropdown or restructure IA); tabs that
  each trigger a full page navigation (use real navigation, not tabs).

### Accordion

- **Intent**: let users progressively disclose long content by expanding one
  section at a time (or several).
- **When to use**: FAQs, long settings forms grouped by topic, content where
  most users only need one section.
- **Composition**: header (button, `aria-expanded`) + collapsible panel per
  `ui-states-interaction` expand/collapse states.
- **Anti-patterns**: nesting accordions more than one level deep; hiding
  content a majority of users need immediately; using an accordion as the only
  way to reach primary navigation.

### Card

- **Intent**: group a single entity's key attributes and actions into a
  scannable, repeatable unit.
- **When to use**: grids/lists of similar items (products, articles, users)
  where users compare or scan many at once.
- **Composition**: media/icon + title + metadata + primary action, spacing per
  `layout-grid-spacing` tokens.
- **Anti-patterns**: cards with inconsistent internal layouts across the same
  grid; cramming unrelated actions into one card; using a card when a table row
  would let users compare data more efficiently.

### Breadcrumbs

- **Intent**: show the user's current location within a nested hierarchy and
  offer quick backward navigation.
- **When to use**: content nested 3+ levels deep (catalogs, docs, settings
  trees).
- **Composition**: ordered list of ancestor links + current page (non-link) +
  separators; pairs with `navigation-design`.
- **Anti-patterns**: breadcrumbs that don't match the real navigable hierarchy;
  using breadcrumbs as the only navigation (they supplement, not replace,
  primary nav); showing breadcrumbs on flat (1-2 level) sites.

### Dropdown / Menu

- **Intent**: reveal a set of secondary actions or options without permanently
  consuming layout space.
- **When to use**: overflow actions, filters, single-select choices from a
  short list (≤ ~10 items).
- **Composition**: trigger button (`aria-haspopup`, `aria-expanded`) + menu
  list with roving keyboard focus and Esc-to-close.
- **Anti-patterns**: burying primary/frequent actions in a dropdown; using a
  dropdown for >10 options (use a searchable list or combobox); nested
  flyout menus more than one level deep.

### Tooltip / Popover

- **Intent**: surface supplementary information on demand without permanent
  screen real estate.
- **When to use**: icon-only button labels, brief clarifying text, truncated
  content on hover/focus.
- **Composition**: trigger (hover + focus, never hover-only) + non-modal
  floating panel positioned to stay in-viewport.
- **Anti-patterns**: putting essential/required information only in a tooltip
  (inaccessible on touch); using a tooltip for interactive content (use a
  Popover/Dropdown pattern instead); tooltips that block the element they
  describe.

### Toast / Notification

- **Intent**: give lightweight, non-blocking feedback about the result of an
  action.
- **When to use**: confirm a background action succeeded/failed (save, send,
  sync) without interrupting the current task.
- **Composition**: transient surface, auto-dismiss with a pause-on-hover
  affordance, optional single action (e.g. "Undo").
- **Anti-patterns**: using a toast for information the user must act on now
  (use a Modal or inline error); stacking more than 2-3 toasts; auto-dismissing
  errors the user hasn't had time to read.

### Stepper / Wizard

- **Intent**: guide users through a sequential, multi-step process toward one
  completion goal.
- **When to use**: onboarding, checkout, multi-stage forms where step N
  depends on step N-1.
- **Composition**: progress indicator (steps, current position) + per-step
  validation + back/next navigation; pairs with `ui-states-interaction` for
  step-level error states.
- **Anti-patterns**: using a wizard for independent, non-sequential settings
  (use Tabs or a single form); wizards with no way to review/edit prior steps;
  more than ~5-7 steps without grouping.

### Data Table

- **Intent**: let users scan, sort, filter, and compare structured records.
- **When to use**: any list of records with 3+ comparable attributes per row.
- **Composition**: header row (sortable columns) + rows + pagination or
  virtualization + empty/loading/error states per `ui-states-interaction`.
- **Anti-patterns**: tables with no empty/loading state; sort/filter controls
  that don't persist across pagination; using a table for 1-2 simple
  attributes (use a List or Card grid instead).

### Command Palette

- **Intent**: give power users a fast, keyboard-first way to find actions,
  content, or navigation without hunting through menus.
- **When to use**: information-dense apps with many actions, keyboard-centric
  or expert users, apps with deep navigation trees.
- **Composition**: global keyboard shortcut trigger + search input + ranked,
  filterable results list with keyboard navigation.
- **Anti-patterns**: making the command palette the *only* way to reach common
  actions (it must supplement discoverable UI, not replace it); no visible
  entry point or shortcut hint for new users.

### Empty State

- **Intent**: orient users when a view has no content yet, rather than
  showing a blank or broken-looking screen.
- **When to use**: first-run experiences, zero search/filter results,
  cleared/completed lists.
- **Composition**: short explanation + primary action to resolve the emptiness
  (create, adjust filters, clear search) per `ui-states-interaction`'s empty
  state contract.
- **Anti-patterns**: a bare "No data" with no next action; identical empty-state
  copy for genuinely different causes (no results vs. no data vs. error).

## Drift prevention

The failure mode this catalog exists to prevent: multiple teams independently
building slightly different versions of the same pattern (see
`style-guide-authoring`'s governance role). Before adding a new pattern
variant, check this catalog and `component-spec` first; if a genuine gap
exists, add it here rather than one-off in a single product surface.
