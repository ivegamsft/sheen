# WAF Assessment Report

Use this template to document the results of an Azure Well-Architected Framework review. Complete each section after evaluating the workload against the five pillars.

## Report Metadata

| Field | Value |
|---|---|
| **Workload Name** | _[name]_ |
| **Workload Description** | _[brief description of the workload and its purpose]_ |
| **Environment** | _[Production / Staging / Development]_ |
| **Azure Region(s)** | _[primary region / secondary region]_ |
| **Assessment Date** | _[YYYY-MM-DD]_ |
| **Assessor** | _[name or agent]_ |
| **Input Artifacts** | _[IaC templates / architecture diagram / workload description]_ |
| **WAF Reference** | [Azure Well-Architected Framework](https://learn.microsoft.com/azure/well-architected/) |

---

## Executive Summary

_Brief overview of the workload, assessment scope, and the most critical findings. Highlight any pillars scoring below 3 that require immediate attention._

### Overall Pillar Scores

| Pillar | Score (1–5) | Trend | Priority |
|---|---|---|---|
| Reliability | | — | |
| Security | | — | |
| Cost Optimization | | — | |
| Operational Excellence | | — | |
| Performance Efficiency | | — | |

**Overall WAF Score:** _[average or weighted score]_ / 5

### Finding Summary

| Severity | Count |
|---|---|
| Critical | |
| High | |
| Medium | |
| Low | |

---

## Pillar Assessments

### Reliability

**Score:** _[1–5]_

**Summary:** _Describe the workload's reliability posture — HA configuration, DR strategy, fault domains, and recovery objectives._

**Target RTO / RPO:** _[e.g., RTO: 1 h, RPO: 15 min]_

#### Findings

| # | Finding | Severity | Recommendation | Effort |
|---|---|---|---|---|
| R-01 | | | | Low / Med / High |

#### Strengths

- _[what the workload does well for this pillar]_

---

### Security

**Score:** _[1–5]_

**Summary:** _Describe the workload's security posture — identity model, network boundaries, data protection, and compliance requirements._

#### Findings

| # | Finding | Severity | Recommendation | Effort |
|---|---|---|---|---|
| S-01 | | | | Low / Med / High |

#### Strengths

- _[what the workload does well for this pillar]_

---

### Cost Optimization

**Score:** _[1–5]_

**Summary:** _Describe current spending patterns, identified waste, and right-sizing opportunities._

**Estimated Monthly Spend:** _[$ amount or range]_

#### Findings

| # | Finding | Severity | Recommendation | Effort |
|---|---|---|---|---|
| C-01 | | | | Low / Med / High |

#### Strengths

- _[what the workload does well for this pillar]_

---

### Operational Excellence

**Score:** _[1–5]_

**Summary:** _Describe the workload's operational maturity — IaC coverage, CI/CD pipeline health, observability, and incident response readiness._

#### Findings

| # | Finding | Severity | Recommendation | Effort |
|---|---|---|---|---|
| O-01 | | | | Low / Med / High |

#### Strengths

- _[what the workload does well for this pillar]_

---

### Performance Efficiency

**Score:** _[1–5]_

**Summary:** _Describe scaling behavior, caching strategies, and observed or projected performance bottlenecks._

#### Findings

| # | Finding | Severity | Recommendation | Effort |
|---|---|---|---|---|
| P-01 | | | | Low / Med / High |

#### Strengths

- _[what the workload does well for this pillar]_

---

## Consolidated Findings

All findings across all pillars, sorted by severity then effort.

| ID | Pillar | Finding | Severity | Impact | Effort | Owner |
|---|---|---|---|---|---|---|
| R-01 | Reliability | | Critical | | Low | |
| S-01 | Security | | | | | |
| C-01 | Cost Optimization | | | | | |
| O-01 | Operational Excellence | | | | | |
| P-01 | Performance Efficiency | | | | | |

---

## Recommended Next Steps

1. _[Highest-priority finding and remediation action — link to remediation-action-plan-template.md]_
2. _[Second priority]_
3. _[Third priority]_

## Sign-Off

| Role | Name | Date | Approved |
|---|---|---|---|
| Assessor | | | ☐ |
| Architect | | | ☐ |
| Workload Owner | | | ☐ |
