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

Compare live DOM/CSS with design intent for token, state, structure, and ARIA parity.

## Workflow
1. Load component specs, token definitions, and live implementation evidence.
2. Read and apply the [parity contract](references/parity-contract.md): evidence flow, scenarios, severity/actions, artifact roles, and schema.
3. Compare spec values with computed CSS, required ARIA, and variants/states; locate each mismatch by file and line.
4. Produce parity/token-drift/variant-coverage reports, apply the gate, and route fixes or spec clarification.

## Guardrails
- Gate requires zero CRITICAL token or ARIA drifts; block the PR for CRITICAL token references outside the system.
- Required focus/error/loading states missing: MAJOR, log issue. Within-range visual deviation: MINOR, log warning and track as issues. Undocumented variants: INFO, document.
- Audit only: do not write new component code, create design specs, or perform infrastructure monitoring.

## Output
- Downstream parity report, token diff table, and missing-variant matrix.
- Reference `audit-report` schema: component/spec, dimension/severity/spec/implementation/file/line findings, severity counts, `gate_passed`.

## Delegates / pairs with
- Triggered by: `design-reviewer` (visual QA), `ci` (pre-merge).
- Input: `design-to-code` (generated), `frontend-dev` (hand-coded).
- Escalates: `ux-designer` (spec clarification), `frontend-dev` (fix).
- Close loop: `design-to-code` → `design-drift-detection` → confirm parity.
