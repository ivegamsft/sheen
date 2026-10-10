# ADR 015 - Wireframing prototype delivery

Status: selected by user directive #287; model and actual HTML browser acceptance
implemented and passing. Downstream visual/task approval remains separate.

## Decision brief

Correct the taxonomy-shaped `wireframing` workflow and deliver tangible low-fidelity
artifacts without creating a parallel skill or promoting prototypes to production.
Constraints: portable skill payload, no framework/runtime service requirement,
explicit output rights, existing blueprint IDs, offline HTML, readable SVG.
Non-goals: Figma replacement, arbitrary canvas editor, production forms or APIs.

## Weighted debate

Scores 1-5 (higher is better). Scores are design estimates, not measured outcomes.

| Criterion | Weight | A: contract/manual generation | B: contract + small deterministic renderer | C: framework/canvas prototype engine |
|---|---:|---:|---:|---:|
| Inspectable, repeatable artifacts | 30% | 2 | 5 | 4 |
| Portability/offline simplicity | 25% | 5 | 4 | 2 |
| Interaction/accessibility testability | 20% | 2 | 4 | 4 |
| Layout expressiveness | 15% | 5 | 3 | 5 |
| Maintenance/scope control | 10% | 5 | 4 | 1 |
| Weighted score | 100% | 3.50 | **4.15** | 3.35 |

A is the conservative baseline: least tooling, most freeform layout, but every
generated prototype must independently implement navigation/escaping/ownership.
B adds a bounded JSON-to-spec/SVG/HTML helper, reusing one ID/flow model and static
interaction behavior; standard-library Python adds an optional host dependency.
C has higher creative upside but brings dependencies, build setup and editor
maintenance outside this skill's purpose.

Evidence: existing wireframing has only SKILL.md/eval.yaml and emits taxonomy;
blueprint already links wireframes to page IDs; design-to-code already owns
framework scaffolds. Style-guide authoring demonstrates portable skill-local
rendering and fail-closed ownership, but its document renderer is not a screen
flow engine and should not be duplicated or forced into that role.

## Outcome and sensitivity

Choose **B**, confidence medium-high. Keep the semantic contract open to manual
generation; the helper is a baseline, not a mandated visual style. At 40%
expressiveness weight (repeatability reduced to 5%), A becomes 4.25 and B 3.65:
bespoke layout-heavy work should use manual rendering under the same validation
contract, not silently extend the helper into a general canvas engine.

Top-two risks: A's per-artifact behavioral drift; B's simplistic stacked layouts
and Python availability. Both are reversible because no runtime app code changes.
Blast radius: existing skill content, bundled outputs, metadata, tests and docs;
no consumer defaults, tokens, agent permissions or enterprise settings.
Revisit if user testing needs drag/drop, arbitrary geometry or complex stateful
logic; hand off to a dedicated prototyping tool rather than production scaffolding.

## Creative calibration

Subject: product screen/flow exploration. Audience: designers and reviewers.
Primary job: inspect structure and click through a proposed task before styling.
Context: offline review, keyboard/mouse, narrow/desktop viewports.
Distinctive focus: hand-sketched screen panels with explicit page/state/target
annotations; restrain decoration so structure remains the review subject.
Anti-template comparison: generic visual chrome may be shared intentionally,
but content, transitions and omissions must trace to the actual brief.
Rejected: taxonomy package, polished framework UI, trend-blacklist styling.
