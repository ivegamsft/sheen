---
name: design-to-code
compatibility: [github-copilot-cli]
description: "Use when generating component code scaffolds from design specs, tokens, or Figma exports. USE FOR: scaffold a React/Vue/Web Component from a component spec, generate token-bound CSS/SCSS from a design spec, convert a wireframe spec to a typed component interface, produce Storybook story shells from component anatomy. DO NOT USE FOR: business logic implementation, backend API design, infrastructure provisioning."
category: development
metadata:
  category: development
  maturity: stable
  audience:
    - developer
    - designer
allowed-tools: []
---
# Design-to-Code Skill

Generate component scaffolds, token bindings, and typed interfaces from `ux` design outputs.

## Workflow
1. Load component/wireframe specs, token definitions or Figma exports, and the requested target/output path.
2. Read and apply the [scaffold contract](references/scaffold-contract.md): generation flow, artifact roles, scenarios, file/token schema, and gate.
3. Scaffold React/CSS Modules, Vue 3 SFC, or vanilla Custom Elements as requested; derive TypeScript props from anatomy and Storybook CSF3 shells for all variants.
4. Bind styles to semantic tokens, verify rendering and built token references, and hand off business logic and visual QA.

## Guardrails
- Gate: the component renders without errors and token references resolve in `dist/tokens/` from the applicable build.
- Do not replace semantic bindings with hardcoded values or silently omit specified variants.
- Generate scaffolds, not business logic, backend APIs, or infrastructure.

## Output
- Downstream component, styles, story, and barrel files under `src/components/{Name}/` (or the requested path), plus a typed interface.
- Reference `component-spec` schema: paths/types and semantic-token/CSS-var/build-value bindings.

## Delegates / pairs with
- Input: `ux-designer` (component-spec), `design-system-architect` (token-spec).
- Output: `frontend-dev` (logic), `design-reviewer` (visual QA).
- Close loop: `design-drift-detection` verifies generated code against spec.
