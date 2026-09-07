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
| Required ARIA state | Toggle: pressed state exposed | pressed state absent | ❌ CRITICAL |
```

**Gate condition:** zero CRITICAL drifts (token or ARIA); MINOR drifts logged as issues

Illustrative ARIA evidence: the accepted Button contract requires a toggle with
an accessible name and exposed pressed state. At `src/components/Button:24`,
the observed native button has its name but omits the required `aria-pressed`
state. This is CRITICAL and blocks the gate, even if recorded as a missing
component state. The other rows illustrate comparisons, not a complete count
or a passing audit; verify token-system membership before classifying token drift.

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
| CRITICAL | Missing or incorrect required ARIA role, name, or state against the accepted component contract | Block PR |
| MAJOR | Required component state missing (focus, error, loading) | Log issue |
| MINOR | Visual deviation within token-defined range | Log warning |
| INFO | Implementation adds undocumented variant | Document |

Required ARIA violations take precedence over MAJOR missing-state findings:
never downgrade an actual required role/name/state violation to MAJOR.
Otherwise, missing required focus/error/loading states remain MAJOR.
Determine requirements from the accepted component contract and valid native
semantics; optional or irrelevant ARIA is not required. Do not add gratuitous
ARIA to native elements or override valid native semantics.
Use N/A with a reason for inapplicable ARIA checks. Missing spec or DOM evidence
is UNKNOWN, not N/A or PASS; request it and leave the check unresolved, not a
passing gate. This framework-neutral audit does not replace downstream
accessibility specialists or their conformance authority.

## Output Schema

```yaml
discriminator: audit-report
component: string
spec_ref: string
checks:
  - dimension: string
    status: PASS | FAIL | N/A | UNKNOWN
    reason: string
    evidence_refs: [string]
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
gate_status: PASS | FAIL | UNRESOLVED
gate_passed: boolean | null
```

Record every evaluated check separately from confirmed severity-bearing drifts.
N/A and UNKNOWN require reasons and available evidence references; identify
missing evidence. They do not count as passing checks or confirmed drifts.
Every confirmed drift must match a FAIL check.

Gate precedence: any confirmed CRITICAL drift means FAIL. Otherwise any UNKNOWN
check, or no applicable checks, means UNRESOLVED. With complete applicable
evidence and no CRITICAL drifts, the gate is PASS; MAJOR/MINOR/INFO actions still
apply. `gate_passed` is true for PASS, false for FAIL, and null for UNRESOLVED.
Null is non-approving: request evidence rather than inventing a failed audit.
Consumers must handle the nullable field and explicit gate status together.

### Gate decision examples

These rows isolate gate logic; they do not replace per-check reasons or evidence.
The illustrative failures below are CRITICAL or MAJOR only.

| Check statuses | Critical | Major | Gate | gate_passed |
|---|---:|---:|---|---|
| UNKNOWN | 0 | 0 | UNRESOLVED | null |
| FAIL, UNKNOWN | 1 | 0 | FAIL | false |
| FAIL, UNKNOWN | 0 | 1 | UNRESOLVED | null |
| FAIL | 0 | 1 | PASS | true |
| PASS, N/A | 0 | 0 | PASS | true |
| N/A | 0 | 0 | UNRESOLVED | null |
| PASS | 0 | 0 | PASS | true |
