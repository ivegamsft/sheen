# Deployment Checklist

Walk through this checklist before and after every production deployment. Skip items only if they are genuinely not applicable — document the reason.

## Pre-Deployment

### Code and Build

- [ ] All CI checks pass on the branch being deployed (lint, test, security scan)
- [ ] The artifact being deployed is the same artifact that passed all prior environment gates — no rebuild
- [ ] Dependency vulnerability scan shows no critical or high severity issues (or they are explicitly accepted with a tracking issue)
- [ ] Container image has been scanned for vulnerabilities

### Configuration and Secrets

- [ ] Environment-specific configuration has been reviewed and is correct for the target environment
- [ ] No secrets are hardcoded in code, config files, or pipeline definitions
- [ ] Secrets required for the deployment are present in the target environment's secret store
- [ ] Feature flags are set to the intended state for this release

### Database and Data

- [ ] Database migrations are backward-compatible (supports rollback without data loss)
- [ ] Migrations have been tested against a production-like dataset
- [ ] Backup of the production database has been taken (or automated backup is verified recent)
- [ ] No destructive schema changes without an explicit migration plan

### Infrastructure

- [ ] IaC changes have been reviewed with `plan` / `what-if` output
- [ ] No unexpected resource deletions or replacements in the plan
- [ ] Resource scaling (replicas, SKU, limits) is appropriate for expected load
- [ ] Network rules and firewall configurations are correct

### Rollback Readiness

- [ ] Rollback procedure is documented and accessible to the on-call team
- [ ] Previous deployment artifact is available for immediate rollback
- [ ] Rollback has been tested in a non-production environment within the last 30 days
- [ ] Database rollback path is confirmed (backward-compatible migrations or restore plan)

### Communication

- [ ] Deployment schedule has been communicated to stakeholders
- [ ] On-call team is aware of the deployment and has access to the rollback runbook
- [ ] Change management ticket or deployment record has been created (if required)

## During Deployment

- [ ] Monitor deployment progress in the CI/CD pipeline
- [ ] Watch for failed health checks or readiness probes during rollout
- [ ] Verify the new version is receiving traffic (check version endpoint or logs)
- [ ] If using canary or blue-green, verify traffic split is correct

## Post-Deployment

### Verification

- [ ] Smoke tests pass against the production environment
- [ ] Health check endpoints return healthy status (`/healthz`, `/readyz`)
- [ ] Key user flows have been manually or automatically verified
- [ ] No unexpected error rate increase in monitoring dashboards

### Observability

- [ ] Logs are flowing and structured correctly
- [ ] Metrics are being emitted (request latency, error rate, throughput)
- [ ] Alerts are active and thresholds are appropriate
- [ ] Distributed tracing is working and spans are correlated

### Cleanup

- [ ] Old deployment artifacts are retained per retention policy (minimum: previous two versions)
- [ ] Temporary feature flags or deployment overrides are cleaned up or scheduled for removal
- [ ] Deployment record or change management ticket is updated with outcome
- [ ] Post-deployment note shared with the team (what changed, any issues observed)

## If Something Goes Wrong

1. **Assess severity** — is the issue affecting users? Check error rates and alerts.
2. **Decide: fix forward or rollback** — if a fix is simple and low-risk, fix forward. Otherwise, rollback.
3. **Execute rollback** — follow the rollback runbook (`skills/devops/rollback-runbook-template.md`).
4. **Communicate** — notify stakeholders of the issue and the action taken.
5. **File a post-incident issue** — document root cause, impact, timeline, and remediation plan.
