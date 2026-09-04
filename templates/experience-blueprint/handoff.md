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
