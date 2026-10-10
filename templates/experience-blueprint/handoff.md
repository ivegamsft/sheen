# Experience Handoff and Documentation Provenance

> Source-linked summary suitable for both human review and agent
> implementation (spec §9 step 7, §13 acceptance criterion 7). This is a
> summary of the experience index — it does not replace it.

## 1. Summary

| Field | Value |
|---|---|
| Experience name | |
| Mode this handoff was produced from | Audit / Generate |
| Primary + supporting archetypes | |
| Overall status | Draft / Ready for review / Accepted |

## 2. Provenance

Every summarized claim below MUST cite its authoritative source: the
experience index artifact ID, an evidence ID (audit), or a decision record
(generate). A generated or rendered summary that cannot name its source is
incomplete.

| Section | Source (artifact/evidence/decision ID) |
|---|---|
| Brand and voice | |
| Selected theme identity/revision, scoped decision and readiness evidence | |
| IA and navigation | |
| Layouts | |
| Pages and states | |
| Wireframes | |
| Flows | |
| Findings / open questions | |

## 3. Implementation dependencies

List what a downstream implementer still needs, without prescribing how to
build it:

- Outstanding design decisions or unresolved questions.
- Specialist artifacts not yet produced (e.g., component specs, tokens).
- Data, content, or integration dependencies referenced by pages/flows.
- Theme application authorization boundary, affected component/layout catalog
  references, unresolved readiness evidence, and migration/recovery owner.
  Reference `theming` records; do not duplicate a theme catalog or treat selection
  as permission to change or deploy the target.
- Recommended next skill/agent (e.g., `design-handoff`, `design-to-code`,
  `frontend-dev`) — the downstream chooses the actual implementation path.

## 4. Review checklist

- [ ] Every page has a purpose, route pattern, layout, states, and
      transitions.
- [ ] Every flow step resolves to a page ID or a declared external
      touchpoint.
- [ ] Navigation destinations exist and are reachable.
- [ ] Responsive behavior is an explicit reflow per breakpoint, not "same as
      desktop."
- [ ] Voice examples cover normal, empty, error, and success moments.
- [ ] Audit claims cite evidence and confidence; generated claims mark
      assumptions and unresolved questions.
- [ ] Every archetype-required moment is represented by a page or flow.
- [ ] This summary's sections are source-linked (§2).

## 5. Optional portable wireframe intake

For `sheen-wireframes/v1`, retain the original model and page/screen/flow IDs.
Validate with `wireframing` and apply `design-handoff`'s skill-local
`references/wireframe-contract.md` and portable sample/checker.
This extends the handoff, not the downstream blueprint's representation.

Supply approved original model baselines separately from this editable handoff.
Missing baselines or any decoded model changes block validation before mappings.
The caller must verify approval at a trusted immutable revision; an embedded
digest does not establish independent trust.

| Source artifact ID | Original model baseline location | Immutable revision / approval evidence | Canonical baseline SHA-256 |
|---|---|---|---|
| | | | |

Carry these fields in the attachment's structured `baseline` record. Verify its
canonical digest against the independent original using the skill-local
contract's fixed JSON normalization (source LF/CRLF whitespace is irrelevant).
Approval reference presence and digest equality do not authenticate approval.

| Source artifact / provenance | Model validation | Visual/task review status and evidence |
|---|---|---|
| | | Pending / Reviewed (not production acceptance) |

| Screen ID | Page / state | Implementation destination | Component/spec references |
|---|---|---|---|
| | | | |

| Screen ID / region / block (zero-based) | Intended production behavior | Dependencies | Simulation limitation |
|---|---|---|---|
| | | | |

| Original flow ID | Screen steps → blueprint step indices | Implementation destination | Coverage gaps |
|---|---|---|---|
| | | | |

Record one row per omitted page state, including permission and partial when
applicable. Cite the page-state contract even when it declares `not-applicable`.

| Page ID | Omitted state | Omission reason | Source page-state contract |
|---|---|---|---|
| | | | |

Record responsive and accessibility limitations separately from structural
validation. Missing visual/task evidence remains pending, not a conformance claim.

| Source artifact / screen IDs | Dimension | Limitation / unresolved behavior | Review status and evidence | Follow-up owner / validation task |
|---|---|---|---|---|
| | Responsive | Breakpoint reflow, ordering and preview fidelity limits | Pending / Reviewed: | |
| | Accessibility | Keyboard, focus, assistive technology and conformance limits | Pending / Reviewed: | |

- [ ] Every mock input/action has a mapping; review-only controls stay review-only.
- [ ] Every omitted page state has a reason, including permission/partial as applicable.
- [ ] Responsive and accessibility limits are recorded; stacked previews are not layout/WCAG proof.
- [ ] Simulated controls/states are not real validation, persistence, authentication,
      payment, network or business effects. Do not copy prototype controls/CSS/JS
      as production implementation.
- [ ] Source/model/mapping revisions agree; positional controls are revalidated after changes.
- [ ] Blueprint-wide validation is separate; pending visual/task review stays a bounded draft.
- [ ] Accepted component/spec mappings go to `design-to-code`; integrations/logic
      go to `frontend-dev`. No handoff grants application write/deploy rights.
