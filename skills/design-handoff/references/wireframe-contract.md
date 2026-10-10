# Portable wireframe handoff

Read for `sheen-wireframes/v1` intake. This is a relationship contract, not
a new wireframe/blueprint schema. Other representations are equally valid.
Both audit and generate modes keep their existing layout/theme rules.

## Sequence and ownership

1. Read the original model; validate with sibling `wireframing`'s
   `scripts/render-wireframes.py::validate`. Supply an approved original model
   separately; compare the complete decoded model before mapping checks.
   Missing baselines block attached handoffs. Never rename page/screen/flow IDs.
2. Resolve every model page and flow to the experience index. A screen is one
   state of one page, not a new page. Keep audit observations separate from
   proposed prototype behavior; simulations are not observed production facts.
3. Map screens to intended implementation destinations and accepted component/
   spec references; do not use the renderer's controls, CSS or JS as production code.
4. Map every input/action to intended production behavior, dependencies and
   limitations. v1 has no control IDs: address controls by screen ID and
   zero-based region/block indices. Revalidate these after any model revision.
5. Map each prototype flow step to an ordered blueprint flow step under the
   same flow ID. Repeated states may map to the same step; omitted steps,
   external touchpoints, branches, cancellation and recovery need explicit
   scope/flow limitations, not claims of complete journey coverage.
6. Record omitted states and reasons, responsive exceptions, source provenance,
   and separate structural checks from actual visual/task review evidence.
7. Run blueprint-wide checks too. Package pending review as a bounded draft.
   Only accepted specs go to `design-to-code`; logic/integration goes to
   `frontend-dev`. Handoff, selection or validation never authorizes writes.

## Illustrative attachment

The complete [blueprint sample](../templates/wireframe-blueprint.json) extends
the existing reference blueprint's JSON example with optional `wireframes`.
It embeds the unchanged v1 model to avoid machine-specific source paths.
The sample's component references are proposed contracts, not bundled runtime
components; resolve/accept them downstream before scaffolding.

Each attachment contains:

- `id`, `source`: unique artifact ID and provenance reference.
  Attachment IDs use blueprint text/tool-native identifiers (including anchors),
  not the model's restricted ID grammar. Validated attachment IDs are indexed
  before audit finding references resolve; global artifact collisions still fail.
- `baseline`: `{revision, approvalEvidence, digest}`. `revision` is
  `git:` plus a full lowercase 40/64-hex commit ID, or `sha256:` plus the
  64-hex canonical model digest. `approvalEvidence` is a nonempty list of
  nonempty approval record references. `digest` must match the independently
  supplied original, not just the attachment. Content revisions must match too.
- `model`: original v1 object; its pages/flows must resolve unchanged.
- `screens`: one `{id, target, components, controls}` per model screen.
  Screen IDs are scoped to the attachment: they may equal page IDs or recur
  in other attachments. Only attachment artifact IDs are globally registered;
  same-kind duplicate IDs within one model/mapping remain errors.
  `target` is a destination/spec reference, never an executable path command.
  `components` lists spec references. Controls contain `region`, `block`,
  `behavior`, `dependencies` (or a reasoned not-applicable entry), `limitations`.
- `flows`: one `{id, steps, target, limitations}` per model flow; `steps`
  holds zero-based blueprint indices in nondecreasing order, one per model
  screen step. Each mapped step must reference that screen's page.
- `states`: page IDs keyed to omitted-state reason maps. Include every
  blueprint state absent from the model and the six baseline states
  default/loading/empty/error/success/permission. Include partial when declared.
  `not-applicable` in the blueprint still requires an omission reason.
- `simulated: true`; `limitations`: nonempty `simulation`, `responsive`,
  `accessibility`, `scope` notes.
- `review`: `status: pending | reviewed`, `evidence` references. Reviewed
  requires recorded visual/task evidence; it is not production acceptance.

Unknown attachment fields, duplicate JSON keys, missing mappings, ID collisions,
inapplicable modeled states and broken relationships block structural handoff.
Legacy blueprints without attachments remain valid; no model is invented.
The checker validates reference syntax/relationships, not the truth of prose,
existence/acceptance of external spec references or completeness of user research.

## Optional read-only command

Sync `design-handoff` AND sibling `wireframing`; Python 3, no packages needed.
From the handoff skill folder in PowerShell:

```powershell
python .\scripts\validate-wireframe-handoff.py --input .\templates\wireframe-blueprint.json --original-model ..\wireframing\templates\task-flow.json
```

Use native paths on other hosts. No artifacts, sidecars or production code are
written. In a source checkout also run `scripts/audit-experience-blueprint.ps1`
on the blueprint; it invokes this checker when attachments are present and
otherwise preserves its existing checks without requiring Python. That
source-only check is not required to read synced skills.

Source-checkout sample command:

```powershell
pwsh .\scripts\audit-experience-blueprint.ps1 -Path .\skills\design-handoff\templates\wireframe-blueprint.json -OriginalModelPath .\skills\wireframing\templates\task-flow.json
```

The sample uses sibling `wireframing`'s original `task-flow.json` as its baseline.
Real callers MUST select a trusted, separately approved immutable revision, not
extract a new baseline from the editable attachment or trust its embedded digest.
Record approval/revision provenance in `baseline` in the handoff. Comparison
checks exact decoded model content (including IDs, annotations and ordering),
not JSON whitespace/key order. It cannot authenticate who approved a supplied
baseline or stop a caller replacing both files; that trust belongs to the caller.
Revisions need a separately approved baseline and regenerated mappings.
Repeat `--original-model` once per attachment; models match independently of
argument order. The source auditor accepts `-OriginalModelPath` with an array of
these paths and uses `python` on Windows, `python3` on other platforms.

Canonical digest: parse JSON, serialize using Python JSON's sorted object keys,
`ensure_ascii=True`, compact `(",", ":")` separators, encode ASCII, with no
trailing newline; SHA-256 is recorded as `sha256:<lowercase hex>`. Array order
and string values are preserved; source LF/CRLF whitespace and key order are
irrelevant. This is a fixed digest convention, not a new artifact schema.
The bundled sample's evidence is explicitly synthetic/example, not real approval.
Digest verification and reference presence do not authenticate approval or
prove a git revision exists; the independent original and caller trust remain
mandatory. Missing/empty provenance, mutable revision labels or digest mismatches
block structural validation.

## Mandatory simulation boundary

Mock input is pretend and optional; actions only navigate simulated screens.
Success/error/loading labels prove no real validation, persistence, data,
authentication, payment, network or business side effects. These need separate
production contracts, integration work and tests. The ordered stacked preview
does not prove responsive layout fidelity, keyboard/task success or WCAG
conformance. Pending evidence stays pending; a structural pass is not sign-off.
