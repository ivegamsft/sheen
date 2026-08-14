# WAF Pillar Scoring Rubric

Use this rubric to assign a 1–5 score to each Well-Architected Framework pillar. Evaluate all criteria for the pillar, then assign the score that best reflects the workload's overall maturity. Record the evidence that supports the score.

## Scoring Scale

| Score | Label | Meaning |
|---|---|---|
| 1 | Not Addressed | No controls or patterns in place; critical risk to the workload |
| 2 | Partial | Some controls exist but significant gaps remain; risk is unmanaged |
| 3 | Foundational | Core best practices are in place; edge cases and advanced patterns are missing |
| 4 | Mature | Most best practices are applied; minor gaps or improvement opportunities remain |
| 5 | Optimized | All best practices are applied; workload exceeds baseline requirements |

---

## Reliability Pillar

**Reference:** [Reliability pillar](https://learn.microsoft.com/azure/well-architected/reliability/)

| Criterion | Weight | 1 | 2 | 3 | 4 | 5 | Score | Evidence |
|---|---|---|---|---|---|---|---|---|
| Availability targets (SLA/SLO) defined | High | No targets | Informal targets | Targets defined | Targets monitored | Targets automated + alarmed | | |
| Multi-region or zone redundancy | High | Single zone, no HA | Some redundancy | Zone-redundant | Multi-region active-passive | Multi-region active-active | | |
| Disaster recovery plan (RTO/RPO) | High | No DR plan | Informal DR | DR documented | DR tested annually | DR tested continuously | | |
| Health monitoring and probes | Medium | No health checks | Basic ping | App-level health endpoints | Dependency health probes | Automated self-healing | | |
| Retry and circuit-breaker patterns | Medium | No retry logic | Manual retry | SDK-level retry | Circuit breaker implemented | Chaos engineering validated | | |
| Data backup and restore validation | Medium | No backups | Ad-hoc backups | Scheduled backups | Backup restore tested | PITR + geo-redundant backups | | |
| Graceful degradation and fallback | Low | No fallback | Partial fallback | Documented fallback | Fallback tested | Automated failover | | |

**Pillar Score:** _[1–5]_

**Scoring Notes:** _Summarize the evidence and key gaps that determined this score._

---

## Security Pillar

**Reference:** [Security pillar](https://learn.microsoft.com/azure/well-architected/security/)

| Criterion | Weight | 1 | 2 | 3 | 4 | 5 | Score | Evidence |
|---|---|---|---|---|---|---|---|---|
| Identity and access management | High | Shared credentials | Basic RBAC | Managed Identity used | Least-privilege RBAC enforced | PIM + conditional access | | |
| Network segmentation | High | All public, no NSG | Some NSG rules | Private endpoints + NSG | Hub-spoke with firewall | Zero-trust micro-segmentation | | |
| Encryption at rest | High | Unencrypted | Platform-default keys | CMK in Key Vault | CMK + key rotation | CMK + HSM + BYOK | | |
| Encryption in transit | High | HTTP allowed | TLS 1.0/1.1 | TLS 1.2 enforced | TLS 1.3 preferred | mTLS between services | | |
| Secret and key management | High | Secrets in code/config | Environment variables | Azure Key Vault used | Key Vault + access policies | Key Vault + Managed Identity only | | |
| Threat detection and SIEM | Medium | No monitoring | Basic alerts | Microsoft Defender enabled | SIEM integrated | Automated response playbooks | | |
| Vulnerability and patch management | Medium | No scanning | Manual patching | Automated patching | CSPM scanning | Continuous compliance enforcement | | |
| Secure software supply chain | Low | No dependency scanning | Manual review | Dependabot enabled | SBOM generated | Signed artifacts + SLSA level 2+ | | |

**Pillar Score:** _[1–5]_

**Scoring Notes:** _Summarize the evidence and key gaps that determined this score._

---

## Cost Optimization Pillar

**Reference:** [Cost Optimization pillar](https://learn.microsoft.com/azure/well-architected/cost-optimization/)

| Criterion | Weight | 1 | 2 | 3 | 4 | 5 | Score | Evidence |
|---|---|---|---|---|---|---|---|---|
| Resource right-sizing | High | Significantly over-provisioned | Some oversizing | Resources roughly right-sized | Right-sized with monitoring | Continuous right-sizing automation | | |
| Reserved or savings plan coverage | High | All pay-as-you-go | Minimal reservations | Core services reserved | 60–80% coverage | 80%+ coverage + auto-renew | | |
| Spot / preemptible workloads | Medium | Not used | Evaluated but not used | Spot used for non-critical | Spot for batch + dev/test | Spot with automated fallback | | |
| Idle and orphaned resource cleanup | High | Many idle resources | Ad-hoc cleanup | Manual reviews scheduled | Automated idle alerts | Auto-decommission pipeline | | |
| Cost allocation and tagging | Medium | No tags | Partial tagging | Required tags enforced | Tags used for chargebacks | FinOps dashboard per team | | |
| Budget alerts and guardrails | Medium | No budgets | Informal budgets | Azure budgets + alerts | Forecasting enabled | Automated cost anomaly response | | |
| Dev/test environment hygiene | Low | Dev mirrors production cost | Some optimization | Dev/test SKUs used | Auto-shutdown schedules | Ephemeral environments | | |

**Pillar Score:** _[1–5]_

**Scoring Notes:** _Summarize the evidence and key gaps that determined this score._

---

## Operational Excellence Pillar

**Reference:** [Operational Excellence pillar](https://learn.microsoft.com/azure/well-architected/operational-excellence/)

| Criterion | Weight | 1 | 2 | 3 | 4 | 5 | Score | Evidence |
|---|---|---|---|---|---|---|---|---|
| Infrastructure as Code coverage | High | Manual deployments | Some IaC | Core infra in IaC | All infra in IaC | IaC with drift detection | | |
| CI/CD pipeline maturity | High | Manual releases | Basic pipeline | Automated build + deploy | Blue-green or canary | Full GitOps with rollback | | |
| Observability (logs, metrics, traces) | High | No observability | Basic logging | Structured logs + metrics | Distributed tracing | Full OpenTelemetry + dashboards | | |
| Alerting and on-call readiness | Medium | No alerts | Email alerts only | Actionable alerts routed | PagerDuty / on-call rotation | Runbooks + auto-remediation | | |
| Runbook and incident response docs | Medium | No runbooks | Informal docs | Key runbooks documented | Runbooks tested | Automated runbook execution | | |
| Change management and deployment safety | Medium | No change controls | Manual approval | Deployment gates | Feature flags | Progressive delivery + observability | | |
| Dependency and lifecycle management | Low | Untracked dependencies | Manual tracking | Inventory maintained | Automated updates | Automated updates + compatibility gates | | |

**Pillar Score:** _[1–5]_

**Scoring Notes:** _Summarize the evidence and key gaps that determined this score._

---

## Performance Efficiency Pillar

**Reference:** [Performance Efficiency pillar](https://learn.microsoft.com/azure/well-architected/performance-efficiency/)

| Criterion | Weight | 1 | 2 | 3 | 4 | 5 | Score | Evidence |
|---|---|---|---|---|---|---|---|---|
| Auto-scaling configuration | High | Fixed capacity | Manual scaling | Rule-based auto-scale | Metric-based auto-scale | Predictive + reactive scaling | | |
| Caching strategy | High | No caching | Ad-hoc caching | Redis Cache deployed | Cache-aside pattern | Multi-level caching + CDN | | |
| Content delivery network (CDN) | Medium | No CDN | CDN for some assets | CDN for all static assets | CDN with custom rules | CDN + edge compute | | |
| Database performance | High | No indexing strategy | Ad-hoc indexes | Core indexes defined | Query performance monitoring | Automatic tuning enabled | | |
| Connection pooling | Medium | No pooling | Basic pooling | Pooling configured | Pool size optimized | PgBouncer / HikariCP tuned | | |
| Load testing and benchmarking | Medium | No load tests | Informal testing | Load tests in CI | Performance budgets defined | Continuous benchmark regression | | |
| Asynchronous and event-driven patterns | Low | Synchronous only | Some async | Message queues used | Event-driven architecture | CQRS + event sourcing | | |

**Pillar Score:** _[1–5]_

**Scoring Notes:** _Summarize the evidence and key gaps that determined this score._

---

## Pillar Score Summary

| Pillar | Score | Interpretation |
|---|---|---|
| Reliability | | |
| Security | | |
| Cost Optimization | | |
| Operational Excellence | | |
| Performance Efficiency | | |
| **Overall** | | |
