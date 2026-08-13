# Architecture Risk Register Template

Use this register to track architectural risks identified during design, review, or implementation. Review and update the register at each architecture checkpoint or sprint boundary.

---

## Risk Register: {System or Project Name}

**Last Updated:** {YYYY-MM-DD}

**Owner:** {Name or team responsible for risk review}

---

### Likelihood and Impact Scale

| Rating | Likelihood | Impact |
|---|---|---|
| **5 — Critical** | Near certain to occur | System failure, data loss, or regulatory violation |
| **4 — High** | Likely to occur | Major feature unavailable or significant performance degradation |
| **3 — Medium** | Possible | Noticeable degradation or increased operational burden |
| **2 — Low** | Unlikely | Minor inconvenience; workaround available |
| **1 — Negligible** | Rare | Cosmetic or trivial impact |

**Risk Score** = Likelihood × Impact (range 1–25)

| Score Range | Severity | Action Required |
|---|---|---|
| 15–25 | 🔴 Critical | Mitigate immediately; escalate to stakeholders |
| 8–14 | 🟠 High | Plan mitigation within current sprint or milestone |
| 4–7 | 🟡 Medium | Schedule mitigation; monitor regularly |
| 1–3 | 🟢 Low | Accept and monitor |

---

### Risk Register

| ID | Risk | Category | Likelihood | Impact | Score | Severity | Mitigation Strategy | Owner | Status |
|---|---|---|---|---|---|---|---|---|---|
| R-001 | {Description of the risk} | {Single point of failure / Scalability / Security / Compliance / Vendor lock-in / Data integrity / Operational} | {1–5} | {1–5} | {L×I} | {🔴🟠🟡🟢} | {Planned mitigation} | {Owner} | {Open / Mitigating / Mitigated / Accepted} |
| R-002 | {Description} | {Category} | {1–5} | {1–5} | {L×I} | {🔴🟠🟡🟢} | {Mitigation} | {Owner} | {Status} |

---

### Risk Categories

| Category | Description |
|---|---|
| **Single point of failure** | A component whose failure takes down the system with no failover |
| **Scalability** | A bottleneck that limits throughput or increases latency under load |
| **Security** | Missing or weak authentication, authorization, encryption, or input validation |
| **Compliance** | Data residency, regulatory, or audit requirements not met by the current design |
| **Vendor lock-in** | Deep dependency on a vendor-specific service with no viable migration path |
| **Data integrity** | Risk of data corruption, loss, or inconsistency due to design gaps |
| **Operational** | Deployment, monitoring, or incident response gaps that increase mean time to recovery |

---

### Governance Rules

- Every risk with a score ≥ 15 (Critical) must have an associated GitHub Issue. Use the issue filing template in the `solution-architect` agent.
- Review the register at every architecture review or sprint boundary.
- When a risk is mitigated, update the status and record what was done. Do not delete rows — the history is valuable.
- New risks discovered during implementation must be added immediately, not deferred to the next review cycle.
