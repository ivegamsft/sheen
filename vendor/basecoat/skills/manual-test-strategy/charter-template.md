# Exploratory Charter Template

Use this template for each time-boxed exploratory testing session. Fill in every field before starting the session. Evidence captured during the session is appended to the **Findings** section.

---

## Charter

**Mission**
_State the specific question this session is trying to answer. One sentence preferred._

> Example: "Explore how the system behaves when a user submits a form with valid input but an expired authentication token."

**Time Box**
_Hard limit on session duration. Stop when this expires regardless of findings._

> `__ minutes` (default: 60 minutes)

**Tester**
_Who is running this session._

**Date**

**Feature / Area**
_What product area or risk theme is in scope._

---

## Scope

**In Bounds**
_List what will be actively tested during this session._

- 
- 

**Out of Bounds**
_List what is explicitly excluded so the session stays focused._

- 
- 

---

## Setup

**Prerequisite state**
_What must be true before starting: accounts, data, environment, feature flags._

- 
- 

**Environment**
_Where the session runs: local, staging, production-like, other._

---

## Evidence Capture

Record findings in real time using the following structure. For bugs, use `defect-template.md`. For other observations, use the format below.

### Observation Log

| # | Time | Area | Observation | Type | Severity |
| --- | --- | --- | --- | --- | --- |
| 1 | | | | Bug / Risk / Question / Insight | Critical / High / Medium / Low |
| 2 | | | | | |

**Types:**
- **Bug** — confirmed defect; fill in `defect-template.md`
- **Risk** — potential issue requiring follow-up investigation
- **Question** — unclear behavior that needs specification clarification
- **Insight** — useful observation that may inform automation or future testing

---

## Triage Routing

| Finding type | Route to |
| --- | --- |
| Bug (critical / high) | File immediately with defect evidence; notify team |
| Bug (medium / low) | File in bug backlog with defect evidence |
| Automation candidate | Hand off to `strategy-to-automation` agent; file GitHub Issue with `automation-candidate` label |
| Risk | Add to risk register or open a tracking issue |
| Question | Raise in spec review or with product owner |

---

## Exit Criteria

The session ends when:
- [ ] The time box expires, OR
- [ ] The mission question is answered with sufficient evidence, OR
- [ ] A blocking bug is found that prevents further exploration of in-scope areas

---

## Findings Summary

_Completed after the session._

**Mission answered?** Yes / No / Partially

**Key findings:**
-
-

**Automation candidates identified:** _[list or reference filed GitHub Issues]_

**Recommended follow-up:**
-
