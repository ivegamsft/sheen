---
# [App-Specific Component Name] — Logical Component Entry

> Status: Draft | Maturity: [draft|beta|stable] | Owner: [team/role]
> Last reviewed: [YYYY-MM-DD]
>
> Implements the logical component contract in
> `specs/11-app-component-catalog.spec.md` §7. This entry is implementation
> neutral — it does not name a framework, CSS system, or file format.
> Delete bracketed placeholder text before publishing.

---

## 1. Identity and provenance

- **Component ID:** [stable-id]
- **Canonical name:** [app-specific name]
- **Aliases:** [alternate names used elsewhere in the app, if any]
- **Purpose:** [the user problem this component solves, one or two sentences]
- **Family / role:** [seed family or app-specific family] · [logical role]
- **Maturity:** [draft|beta|stable] · **Owner:** [team/role] · **Review status:** [pending|approved]
- **Authoritative sources / evidence:** [design system reference, observed
  usage, research, or decision record]
- **Relationship to shared/upstream component:** [none | derived from `<name>`]
- **Implementation bindings (optional):** [links to code, design assets,
  previews, or tests — none required]

## 2. Usage rules

- **Use when:** [criteria]
- **Do not use when:** [criteria; name the preferred alternative]
- **Preferred alternatives:** [component names]
- **Applicable audiences / tasks / page types:** [list]
- **Required / optional / restricted / prohibited contexts:** [list]
- **Characteristic misuse:** [anti-patterns observed or anticipated]

## 3. Placement rules

- **Allowed layout-region roles:** [logical region roles, not selectors]
- **Prohibited layout-region roles:** [logical region roles]
- **Applicable IA levels / navigation contexts:** [list]
- **Prominence, frequency, density, repetition constraints:** [describe]
- **Required adjacency or separation:** [describe]
- **Modal / inline / persistent / sticky / transient / overlay behavior:** [describe]
- **Page, flow, and journey relationships:** [link to Experience Blueprint
  pages/flows once available]

## 4. Composition

- **Parent / container roles:** [list]
- **Child, slot, or content roles:** [list]
- **Required vs. optional subcomponents:** [list]
- **Compatible / incompatible sibling components:** [list]
- **Logical dependencies:** [list]
- **Replacement, extension, composition rules:** [describe]
- **Maximum useful nesting or repetition:** [describe, if relevant]

## 5. Styling abstractions

> Describe intent and abstractions only — do not prescribe a CSS framework,
> raw class list, or another design system's visual treatment.

- **Semantic token roles:** [e.g. surface, emphasis, boundary — name the
  app's own roles]
- **Visual emphasis / hierarchy:** [describe]
- **Density, size, spacing behavior:** [describe]
- **Shape, border, elevation, imagery, icon, motion roles:** [describe]
- **Theme / high-contrast expectations:** [describe]
- **Allowed variants / prohibited visual divergence:** [describe]

## 6. Data and content requirements

- **Data purpose / domain entity:** [describe; reference an existing data
  contract, do not invent fields]
- **Required / optional fields:** [list]
- **Cardinality, ordering, grouping, filtering, pagination needs:** [describe]
- **Data freshness / update behavior:** [describe]
- **Loading, empty, partial, error, stale, permission states:** [describe]
- **Error-state note:** error and empty-state copy must explain the problem
  and a path to resolution without exposing system internals or sensitive
  data (no information leak).
- **Sensitive-data, privacy, localization, formatting considerations:** [describe]
- **Copy, label, help, and error-message requirements:** [describe]

## 7. Behavior and states

- **Default, hover, focus, active, selected, disabled, loading, error,
  success behavior:** [describe as applicable]
- **Trigger, dismissal, confirmation, undo behavior:** [describe]
- **Keyboard, pointer, touch, voice, assistive-technology expectations:**
  [name the interaction pattern and focus-management behavior; this is
  behavior, not a specific ARIA/DOM implementation]
- **Focus management, announcements, semantic role:** [describe]
- **Destructive / irreversible / high-risk interaction treatment:** [describe]

## 8. Responsive and adaptive behavior

- **Content priority / minimum useful presentation:** [describe]
- **Allowed resizing, reflow, wrapping, stacking, collapsing, substitution,
  overflow behavior:** [describe]
- **Behavior in constrained, expanded, touch, high-density contexts:** [describe]
- **Information/actions that must remain available:** [describe]
- **When a different logical component is preferred instead:** [describe]

## 9. Selection metadata

Use these criteria to compare this candidate against alternatives:

- User intent and task criticality: [describe]
- Content/data type and cardinality: [describe]
- Available region role and space: [describe]
- IA depth and navigation context: [describe]
- Interaction complexity and frequency: [describe]
- Audience expertise and accessibility needs: [describe]
- Device/input context: [describe]
- Density, urgency, persistence: [describe]
- Existing app patterns and consistency cost: [describe]

## 10. Decision record

- **Reused / extended / newly specified:** [choose one]
- **Rationale:** [why this decision satisfies the need]
- **Rejected alternatives:** [name close alternatives and why they were
  rejected]
- **Uncertainty or missing evidence:** [call out anything not yet confirmed]

## 11. Gallery notes

- **Discoverable by:** name/alias, family/role, task/page type, layout-region
  role, data shape/interaction type, maturity/review status, usage
  restriction, composition/dependency.
- **Visual example (optional):** [link — a preview never substitutes for the
  logical specification above]
