---
name: wireframing
compatibility: [github-copilot-cli]
description: "Create low-fidelity screen and flow artifacts before visual design. USE FOR: screen wireframe specifications, sketched SVG wireframes, offline HTML click-through prototypes, layout hierarchy planning, flow skeleton definition. DO NOT USE FOR: production component scaffolding (design-to-code), taxonomy modeling (taxonomy), final visual polish, token refactoring."
category: ia
metadata:
  category: ia
  maturity: stable
  audience: [designer, developer]
  pillar: ia
allowed-tools: []
---

# wireframing

Create screen specifications, sketched SVG boards, or offline HTML click-throughs.

## Workflow
1. Read and apply the [artifact contract](references/artifact-contract.md).
2. Capture the task, audience, existing page/flow IDs, layout constraints, states and content priorities. Mark assumptions; preserve approved decisions.
3. Select fidelity, output format and authorized destination; default to a screen specification. Explore alternatives with `design-debate` when structure is uncertain.
4. Model screens, ordered regions, controls, targets and flow edges. Use the [sample](templates/task-flow.json) as a complete portable example, not product evidence.
5. Generate the selected artifact; optionally use bundled `scripts/render-wireframes.py` (Python 3). Richer manual artifacts follow the same contract.
6. Validate references and actual output. For HTML, exercise keyboard/mouse, Back/Reset, focus, states and narrow viewports; record visual/task findings before handoff.

## Guardrails
- Never present a prototype as production UI or user-validation evidence.
- Simulate interactions only: no real data submission, services, payments or credentials.
- No deployment, unrelated overwrite or silent state omission; refresh only verified owned output with explicit authorization.
- Static SVG is a storyboard, not a clickable prototype. Do not infer accessibility compliance from a screenshot or renderer pass.

## Output
- Selected screen-spec Markdown, sketched SVG board, or self-contained HTML at the requested destination.
- Page/screen/state/flow references, annotations, assumptions and review findings; helper outputs include an ownership sidecar.

## Delegates / pairs with
- layout-grid-spacing
- ui-states-interaction
- experience-blueprint
- design-debate
- accessibility-audit
- design-to-code
