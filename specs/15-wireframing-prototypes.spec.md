# Spec 15 - Wireframing and Portable Prototypes

> Extends the existing `wireframing` skill. User directive and delivery: #287.
> Implementation status: skill-local renderer and model/browser regression gates
> implemented under #287. These gates validate the helper/sample, not downstream
> user-task success or accessibility certification.

## 1. Ownership and scope

`wireframing` owns low/mid-fidelity screen composition and flow simulation,
not taxonomy, final visual design, or production components. Preserve the
published skill name. `experience-blueprint` owns the experience index and
relationships; `design-to-code` owns production-oriented component scaffolds.

The skill MUST read its local artifact contract before generating. It MUST offer:
screen specification, sketched SVG board, and self-contained HTML click-through.
Absent a format request, use a screen specification; never imply HTML writes
or deployment are authorized. Record the requested destination and fidelity.
Existing approved IA, layout, brand and component decisions remain authoritative.

## 2. Model and evidence

An optional portable renderer consumes `sheen-wireframes/v1` JSON:
title, start screen, unique page IDs, screens and flows. Each screen has a unique
safe ID, exactly one declared page ID, a state, annotations, and ordered regions.
Regions contain text, input, placeholder or action blocks. Actions require
declared target screen IDs. Each flow has a unique ID and a nonempty sequence of
declared screens; adjacent steps MUST have an explicit action between them.
Every screen MUST be reachable from the start. Page IDs match downstream
blueprint IDs when supplied; standalone artifacts declare their own IDs.

Supported states: default, empty, loading, error, success. Do not invent
irrelevant states; enumerate omitted states and assumptions in annotations.
Do not claim complete journey coverage or conformance merely because the model
is valid. The author MUST separately identify required states, responsive
behavior, content priority, and uncertainty before handoff.

## 3. Outputs

- **Screen specification:** page/screen IDs, regions/content order, controls and
  targets, states, flow steps, annotations, and validation tasks.
- **SVG:** deterministic sketch-like monochrome board, readable labels and
  control destinations, one panel per screen, title/description, scalable
  viewBox. It is a static storyboard, not an interactive prototype.
- **HTML:** one offline file with inline CSS/JS, semantic sections, visible
  prototype banner, native labeled controls, explicit screen/state labels,
  linked screen transitions, Back and Reset, keyboard focus transfer to the
  active screen heading, and responsive region stacking.
- Form inputs MUST be explicitly simulated; no submit, network, storage,
  authentication, real payment, or business side effects. Reset clears simulated
  input and history. Unknown fragment IDs fail visibly and provide recovery.
- No external fonts, assets, scripts or fetches; escape untrusted model text.
  Static scripts use a hash-based CSP; SVG MUST NOT contain executable content.
  Renderer rejects unknown fields/kinds and malformed IDs instead of silently
  dropping requested behavior.

The baseline renderer intentionally uses an ordered stacked sketch layout;
it does not infer pixel fidelity or arbitrary geometry from a product brief.
Authors may produce richer artifacts under the same semantic/evidence contract,
but MUST validate their actual output rather than claiming the helper did so.

## 4. Safe publication and portability

Bundle the helper, complete sample and contract inside the skill so consumer
sync remains independent. Python 3 is an optional renderer prerequisite; do not
install dependencies or require source-repository tooling to read/use the skill.
Outputs go only to the explicit requested path. Reject symlink/reparse output
paths/ancestors and collisions with source or unrelated content. A generated
ownership sidecar records schema, format, input/output SHA-256. Refresh requires
explicit `--replace-owned` and verified current output hash. Missing or modified
ownership evidence blocks writes; identical output is a byte/timestamp no-op.
No broad directory deletion or cleanup of other tools' files.

## 5. Validation and delivery

Regression gates MUST exercise all formats, deterministic no-op, ownership
conflicts, invalid/dangling/duplicate IDs, unreachable screens, broken flow
edges, unknown fields, injection escaping, and absence of external resources.
Browser tests MUST exercise the actual HTML: mouse and keyboard transitions,
Back/Reset including input clearing, focus, unknown-route recovery, and narrow
viewport overflow; no console errors or unexpected network requests.
Routing evals include positive SVG/HTML/spec requests and negative production
component and taxonomy requests. Regenerate complete skill metadata; preserve
existing catalog registration and update directly related handoff docs.

Prototype readiness requires model validation AND recorded visual/task review.
Passing renderer/browser tests is not accessibility certification or user validation.
Rollback uses a governed revert and restores only verified owned artifact revisions.

## 6. Blueprint and production handoff

`experience-blueprint` and `design-handoff` MUST accept the original v1 model
without renaming page/screen/flow IDs or changing renderer behavior. The model
remains prototype evidence, not a production component contract. Spec 10 §6.7.1
governs screen/component destinations, positional input/action mappings,
ordered flow-step relationships, omitted-state reasons and simulation limits.
Reuse the existing model validator; keep the illustrative attachment, sample
and read-only relationship checker local to the handoff skill. Its shared
validator dependency is `wireframing`, not source-checkout scripts.
Require separately supplied approved original model baselines and exact decoded
model comparison before mapping checks; never trust caller-editable embedded
digests as independent identity evidence. Missing baselines block attached
handoffs; unattached legacy blueprints remain unaffected.
Blueprint-wide validation remains separate. A structural pass MUST NOT approve
mock behavior, authorize application writes, or replace visual/task review.
