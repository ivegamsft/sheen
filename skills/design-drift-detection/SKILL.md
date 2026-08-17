---
name: design-drift-detection
compatibility: [github-copilot-cli]
description: "Use when auditing whether a live implementation matches its design spec or token definitions. USE FOR: compare rendered DOM against a component spec, detect token value drift between spec and CSS, flag missing ARIA attributes not in wireframe, generate a spec-vs-implementation parity report. DO NOT USE FOR: writing new component code, creating design specs, infrastructure monitoring."
category: development
metadata:
  category: development
  maturity: stable
  audience:
    - developer
    - designer
    - qa
allowed-tools: []
---
# Design Drift Detection Skill

Audit whether live implementation matches design intent — catching token drift, missing states, structural divergence, and ARIA gaps before they reach production.

## Closes

GitHub issue #60 — `feat(skill): design-drift-detection — spec-vs-implementation parity audit`

## Workflow

```
component-spec + live DOM/CSS → design-drift-detection → parity report
                              ↘ token drift table
                              ↘ ARIA gap list
                              ↘ missing variant matrix
```

## Templates in This Skill

| Template | Purpose |
|---|---|
| `drift-report-template.md` | Spec-vs-implementation parity report with severity ratings |
| `token-drift-table.md` | Token value diff: spec value vs. computed CSS value |
| `variant-coverage-matrix.md` | Component variant/state coverage matrix |

## Sample Prompts

### Full parity audit

```
@design-drift-detection audit src/components/Button/ against docs/components/button.spec.md
```

**Agent flow:** `design-reviewer` → `design-drift-detection` → `frontend-dev` (fixes)

**Output shape:**
```
## Drift Report: Button
| Dimension        | Spec                    | Implementation        | Status  |
|------------------|-------------------------|-----------------------|---------|
| Background token | --color-action-primary  | --color-brand-blue    | ❌ DRIFT |
| Focus ring       | 2px solid --focus-ring  | missing               | ❌ MISSING |
| Hover state      | defined                 | defined               | ✅ MATCH |
```

**Gate condition:** zero CRITICAL drifts (token or ARIA); MINOR drifts logged as issues

### Token drift only

```
@design-drift-detection check token bindings in src/components/ against tokens/semantic/
```

### Missing variant audit

```
@design-drift-detection generate a variant coverage matrix for src/components/Card/
against docs/components/card.spec.md
```

## Drift Severity Levels

| Level | Trigger | Action |
|---|---|---|
| CRITICAL | Token value does not reference design system | Block PR |
| MAJOR | Required component state missing (focus, error, loading) | Log issue |
| MINOR | Visual deviation within token-defined range | Log warning |
| INFO | Implementation adds undocumented variant | Document |

## Output Schema

```yaml
discriminator: audit-report
component: string
spec_ref: string
drifts:
  - dimension: string
    severity: CRITICAL | MAJOR | MINOR | INFO
    spec_value: string
    impl_value: string
    file: string
    line: number
summary:
  critical: number
  major: number
  minor: number
  info: number
gate_passed: boolean
```

## Agent Pairing

- Triggered by: `design-reviewer` (visual QA), `ci` (pre-merge gate)
- Input from: `design-to-code` (generated components), `frontend-dev` (hand-coded)
- Escalates to: `ux-designer` (spec clarification), `frontend-dev` (fix)
- Closes loop: `design-to-code` → `design-drift-detection` → confirm parity
