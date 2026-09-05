# App-specific theme lifecycle

The existing `theming` skill now coordinates **audit, compare, select, generate,
revise, and authorized application** using one logical contract. The
`design-system-architect` owns composition; downstream brand/design-system
decisions remain authoritative. There is no new agent, skill, preset palette,
font bundle, runtime adapter, or required downstream storage/rendering format.

## Start with your actual application

Supply the brief and accepted decisions; target surfaces, contexts, required
modes/states; existing theme selections; font permissions/capabilities; safe
representative content; and downstream decision/change policy. Unknown mandatory
evidence blocks readiness. A missing preview does not prove a theme is absent.

The synced skill includes its own relative
`references/lifecycle-contract.md` and `templates/lifecycle-record.md`.
These work within the synced skill folder without requiring this repository's
specs or test scripts. The worksheet is optional: preserve its concepts in your
existing documents/records. Source versions:

- [Theming skill](https://github.com/IBuySpy-Shared/basecoat-sheen/blob/main/skills/theming/SKILL.md)
- [Shared contract](https://github.com/IBuySpy-Shared/basecoat-sheen/blob/main/skills/theming/references/lifecycle-contract.md)
- [Record worksheet](https://github.com/IBuySpy-Shared/basecoat-sheen/blob/main/skills/theming/templates/lifecycle-record.md)
- [Spec 13](https://github.com/IBuySpy-Shared/basecoat-sheen/blob/main/specs/13-theme-lifecycle.spec.md)

## Supported paths

| Request | Agent path / output | Boundary |
|---|---|---|
| Audit current themes | Inventory observed usage; map to candidates/decisions; classify applicable variants, drift, and unknowns with evidence/confidence/impact/action | No target changes without a separate authorized task |
| Discover/compare | Filter purpose, audience, surface/mode, maturity/status, limitations; compare exact revisions with shared content/conditions and visible failures | Logical comparison is allowed without rendering; required visual evidence stays blocked |
| Reuse approved choice | Record revision/scope/constraints/capability/evidence applicability; reuse without redundant confirmation | Changed conditions trigger reassessment; approval is not inferred from silence |
| Custom request | Prefer reuse, extend a valid semantic purpose, or justify creation for an unmet need; ground in accepted app decisions | Same preview, selection, readiness, and authorization gates as existing themes |
| Apply | Check exact scoped selection, mandatory gates, separate change authority, impact and recovery; use supported downstream mechanism | No automatic file writes or deployment from selection/readiness alone |
| Revise/migrate | Preserve predecessor/selection history; identify affected consumers and invalidate stale evidence | Bound reassessment only with recorded justification; preserve unaffected approvals |

### Example request

> Compare our two staff-review theme revisions on the queue and detail surfaces.
> Use the same safe dense content, long translated labels, error and focus states,
> and required light mode. Reuse decision-7 only if applicable. Inspect font use
> permission and fallback fit; do not install anything. Produce a bounded handoff
> because this task does not authorize application.

Expect linked candidate/comparison, selection/applicability, readiness/impact/
recovery and handoff records, **not** an invented approval or a changed application.
For a static document, explain why interaction states are N/A; for interactive
targets, cover required states. No PDF or screenshot-only requirement is imposed.

## Blocked paths and recovery

- Unsupported preview tools: provide an explicitly unverified plan or logical
  comparison. Do not claim visual readiness or install a renderer/font silently.
- Brand conflict or missing decision authority: keep selection pending and
  propose resolution through brand ownership / `design-debate`. Downstream policy
  may explicitly delegate approval to an agent; no universal human gate is added.
- Missing semantic concept: preserve current keys and hand the gap to
  `design-tokens`, rather than inventing a theme-specific semantic key.
- Unknown font permission, missing weights/scripts, or failed fallback fit:
  obtain an acceptable authorized fallback and evidence or remain blocked.
- Failed contrast in one required state: report criterion, pair, mode/state,
  measurement, and effect. Normal text AA is 4.5:1; large text and applicable
  non-text information 3:1; honor stricter criteria and justified exemptions.
  Palette measurements are not whole-artifact WCAG conformance.
- Unsupported mapped expression: document limitation and owner; no hidden
  substitution. Missing mandatory evidence and unjustified N/A remain blocking.
- Partial application or post-review failure: preserve actual changed targets,
  distinguish failed/unattempted targets, withhold completion, retain Applied
  history, and propose authorized recovery without overwriting unrelated work.
  Repeating an unchanged reviewed application is a no-op.

## Ownership and Experience Blueprint

Theming coordinates, but brand, typography/font mapping, semantic token,
contrast/accessibility, and representative review specialists retain depth.
The Blueprint and engineering handoff reference selected identity/revision,
decision/evidence, readiness and authorization limits, affected component/layout
catalog entries, unresolved findings, and recovery owner. They do not copy the
theme catalog or transfer implementation authority.

Brand-only work stays with `brand-identity` / `brand-voice-tone`. Reporting-only
work stays with `data-visualisation`; supported non-reporting documentation
diagrams route to `documentation-diagram`. Merely styling a dashboard does not
authorize changing chart/data semantics or broad application theming.

## Verification and evidence limits

[Coverage and worked inputs/outputs](https://github.com/IBuySpy-Shared/basecoat-sheen/tree/main/tests/fixtures/theme-lifecycle)
cover T01–T14, including supported and blocked branches. Run from the Sheen repo:

```powershell
pwsh -NoProfile -File scripts\test-theme-lifecycle.ps1 -OutFile dist\theme-lifecycle-evidence.json
pwsh -NoProfile -File scripts\test-eval-routing.ps1
```

The first executes a small illustrative decision evaluator against explicit
synthetic evidence, checks expected decisions, and verifies incorrect-output
rejection. The optional report expands every inherited input beside expected and
actual outputs. It is not a production adapter, general downstream validator,
LLM behavioral benchmark, or required schema. The second checks routing
activation/specificity, not lifecycle behavior.

Neither proves rendered quality or downstream dogfood success. A real application
still needs its own supported preview evidence, font/capability/criterion review,
authorized changes, and representative post-application review. This implementation
ships agent contracts and worked decision evidence, not a deployed product theme.
