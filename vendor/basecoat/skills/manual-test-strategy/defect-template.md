# Defect Evidence Template

Use this template whenever a defect is found during manual testing, an exploratory session, or a regression run. Evidence must be rich enough for any team member to reproduce the issue without tribal knowledge. This template also serves as the handoff record for CI triage, bug filing, and future automation.

---

## Defect Record

**Title:** _[Short, specific description of what is wrong]_

**Reported by:**
**Date:**
**Environment:** _[local / staging / production-like; OS, browser if relevant]_
**Build / Version / Commit:**
**Severity:** Critical / High / Medium / Low
**Priority:** High / Medium / Low

---

## Reproduction Steps

_List every step required to reproduce the defect from a clean state. Be precise: another tester should be able to follow these steps without asking questions._

1. Start in state: _[describe the required starting state, accounts, data, feature flags]_
2.
3.
4.

**Reproducibility:** Always / Intermittent (___ of ___ attempts) / Not reproduced after filing

---

## Expected Result

_What should have happened based on the specification, design, or reasonable user expectation._

---

## Actual Result

_What actually happened. Include exact error messages, status codes, or visible behavior._

---

## Impact

**Who is affected:** _[all users / authenticated users / admin only / specific segment]_
**Business impact:** _[describe the consequence: data loss, blocked workflow, degraded UX, etc.]_
**Workaround available:** Yes / No — _[if yes, describe it]_

---

## Diagnostic Context

_Include any information that helps with root cause analysis or triage. Remove anything that is already obvious from the reproduction steps._

**Logs / error output:**
```
[paste relevant log lines or error output here]
```

**Screenshots or recordings:** _[attach or link]_

**Telemetry references:** _[trace IDs, request IDs, correlation IDs if available]_

**Related tests that should have caught this:** _[list any existing tests or checklist items that cover this area — note if coverage was missing]_

---

## Automation Handoff

_Complete this section if the defect should be prevented by an automated check going forward._

**Should this become an automated test?** Yes / No / Already covered (gap in execution)

**Test type:** smoke / regression / integration / other

**What the automated check should validate:**
_[plain-language description of the assertion, no tooling specifics]_

**Acceptance criteria for the automated check:**
- [ ]
- [ ]

_If yes, hand off to the `strategy-to-automation` agent and file a GitHub Issue with labels `testing` and `automation-candidate`._

---

## Status

| Field | Value |
| --- | --- |
| Filed in tracker | Yes / No — [link or ID] |
| Assigned to | |
| Fix version | |
| Verified fixed | Yes / No / Pending |
