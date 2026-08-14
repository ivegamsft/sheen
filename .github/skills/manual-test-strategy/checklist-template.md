# Manual Regression Checklist Template

Use this template to build a repeatable manual regression checklist. Each item must be runnable by a new team member without tribal knowledge. Items that pass the repeatability bar and are run frequently are strong automation candidates.

---

## Context

**Feature / Area:**
**Version / Build:**
**Date:**
**Tester:**
**Environment:**

---

## How to Use

1. Run each item in order unless the item notes an exception.
2. Mark each item as **Pass**, **Fail**, or **Skip** with a reason.
3. For failures, fill in a defect record using `defect-template.md`.
4. For skipped items, note why and whether they need a follow-up session.
5. After the run, complete the **Run Summary** section.

---

## Checklist Items

### Group: [Area name — e.g., Core happy path]

| # | Step | Expected result | Pass / Fail / Skip | Notes |
| --- | --- | --- | --- | --- |
| 1.1 | | | | |
| 1.2 | | | | |
| 1.3 | | | | |

### Group: [Area name — e.g., Negative and error paths]

| # | Step | Expected result | Pass / Fail / Skip | Notes |
| --- | --- | --- | --- | --- |
| 2.1 | | | | |
| 2.2 | | | | |
| 2.3 | | | | |

### Group: [Area name — e.g., Edge cases and boundary conditions]

| # | Step | Expected result | Pass / Fail / Skip | Notes |
| --- | --- | --- | --- | --- |
| 3.1 | | | | |
| 3.2 | | | | |

---

## Automation Candidate Flags

Mark any item that is a strong automation candidate.

| Item # | Reason it should be automated | Priority |
| --- | --- | --- |
| | | |

Items flagged here should be handed off to the `strategy-to-automation` agent with a GitHub Issue filed using the `automation-candidate` label.

---

## Run Summary

| Metric | Count |
| --- | --- |
| Total items | |
| Passed | |
| Failed | |
| Skipped | |

**Overall result:** Pass / Fail / Incomplete

**Blocking failures (if any):**
-

**Defect records filed:**
-

**Automation candidates flagged:**
-

**Next actions:**
-
