# Component Catalog Audit and Selection Contract

Read for both modes. Implements
[spec 11](https://github.com/IBuySpy-Shared/basecoat-sheen/blob/main/specs/11-app-component-catalog.spec.md)
(ADR-011). The downstream
design system is authoritative; the neutral seed vocabulary only detects
gaps — rename, merge, or drop families to fit the app. Never copy another
library's components, code, or visuals.

## Neutral seed families

Actions, input/selection, navigation, feedback/status, disclosure/overlays,
content/media, data display, structure, task composition. See
[role table](https://github.com/IBuySpy-Shared/basecoat-sheen/blob/main/docs/components/app-component-catalog.md)
and [component entry template](https://github.com/IBuySpy-Shared/basecoat-sheen/blob/main/templates/app-component-catalog/component-entry.md)
in the sheen source repository for the full role table and logical metadata.
These shared resources are not paths inside a synced skill folder.

## Audit workflow

1. Load the app's design system, Experience Blueprint, layout catalog, and
   shared/pattern inventories.
2. Inventory implementation bindings, design assets, and observed page usage
   in the stated scope.
3. Group candidates by purpose, semantics, and alias evidence — not
   appearance or name alone — to normalize duplicate labels.
4. Classify each group as one component with legitimate variants,
   implementation drift, or genuinely distinct components; distinguish a
   component from a pattern, a layout region, and a page.
5. Record findings with evidence, confidence, impact, affected pages, and a
   recommended catalog action.

## Generate workflow

1. Read the audience, task, page/layout region, data, state, and
   accessibility context.
2. Search the catalog by name, alias, role, and constraint; eliminate
   candidates whose do-not-use, placement, data, or responsive rules
   conflict.
3. Reuse a fitting component; extend only if its core purpose survives;
   specify a new one only for a distinct unmet need — never for a visual
   difference alone.
4. Complete identity, usage, placement, composition, styling abstractions,
   data/content, behavior/states, and responsive metadata.
5. Add the accepted entry to the app gallery with provenance and document
   why it was reused, extended, or created, plus rejected alternatives.

## Guardrails

- Do not let an implementation binding stand in for the logical contract.
- Do not treat the seed vocabulary as a required inventory.
- Flag ambiguous aliases, undocumented dependencies, one-off components, and
  mobile behavior that drops the primary task.

## Output

- Logical component catalog entries (audit) or a new/updated entry with
  selection rationale and gallery placement (generate).
