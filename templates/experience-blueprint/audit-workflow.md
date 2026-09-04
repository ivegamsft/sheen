# Audit Workflow: Evidence, Confidence, Maturity, and Findings

> For **audit mode** (spec §8, §10). Populate this alongside
> `experience-index.md`. Every claim in this document MUST trace to an
> evidence entry — an audit MUST NOT claim a page, flow, or state is absent
> unless the audited scope and evidence sources make that conclusion
> supportable.

## 1. Scope

| Field | Value |
|---|---|
| Platforms/environments audited | |
| Roles/permissions audited | |
| Explicitly out of scope | |
| Audit date range | |

## 2. Evidence register

| Evidence ID | Location | Type (code / screenshot / live page / analytics / test / doc) | Captured | Confidence (low/med/high) |
|---|---|---|---|---|
| `ev-001` | | | | |

- **Confidence** reflects how directly the evidence supports the claim (a
  live production capture is higher confidence than a stale doc).
- Link every evidence ID from the findings and maturity tables below —
  findings without an evidence reference are not admissible.

## 3. Inferred archetype composition

Record the archetype(s) the application currently appears to implement, and
mark inference vs. confirmed intent explicitly.

| Archetype | Status (confirmed / inferred / assumed) | Evidence |
|---|---|---|

## 4. Maturity scoring (0-4 per dimension)

| Score | Meaning |
|---|---|
| 0 | Missing or unusable |
| 1 | Ad hoc and inconsistent |
| 2 | Partially defined |
| 3 | Defined and mostly consistent |
| 4 | Governed, validated, and traceable |

| Dimension | Score (0-4) | Evidence | Confidence | Notes |
|---|---|---|---|---|
| Brand | | | | |
| Voice | | | | |
| IA | | | | |
| Layout | | | | |
| Page/state coverage | | | | |
| Navigation | | | | |
| Task-flow continuity | | | | |
| Responsive/accessibility readiness | | | | |
| Cross-artifact coherence | | | | |

Scores are prioritization signals, not compliance certifications.

## 5. Findings

| Finding ID | Severity (critical/major/minor/enhancement) | Affected artifact ID(s) | Evidence | User impact | Recommendation | Owner |
|---|---|---|---|---|---|---|
| `find-001` | | | `ev-*` | | | |

## 6. Fact / inference / proposal separation

Keep these three explicitly separate — never blend them in one statement:

- **Observed facts** — directly evidenced current behavior.
- **Inferred intent** — a plausible reason for the observed behavior, marked
  as inference.
- **Proposed future state** — a recommendation, not a description of what
  exists today.

## 7. Prioritized remediation

Order findings into: quick wins, medium-term fixes, and structural fixes.
Separate contract fixes (this blueprint), design-system fixes, page fixes,
and implementation fixes so each routes to the right owner.
