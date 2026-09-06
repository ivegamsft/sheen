# Parity Audit Contract (#60)

Read before auditing. Apply the severity/action table and schema to full,
token-only, and variant-coverage audits. Example spec/source paths belong
to the downstream project.

## Evidence flow

```
component-spec + live DOM/CSS → design-drift-detection → parity report
                              ↘ token drift table
                              ↘ ARIA gap list
                              ↘ missing variant matrix
```

## Report artifact roles

These suggested downstream artifact names are not bundled template files;
author them using the severity table and schema below.

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
