# Environment Promotion Template

Use this template to define the promotion path for a service from development through production. Customize gates, approvals, and checks to match your organization's requirements.

## Promotion Path

```
┌───────┐     ┌──────────┐     ┌─────────────┐
│  Dev  │ ──► │ Staging  │ ──► │ Production  │
└───────┘     └──────────┘     └─────────────┘
  auto          auto + gate       manual approval
```

## Environment Definitions

| Environment | Purpose | Deployment Trigger | Approval Required |
|---|---|---|---|
| **Dev** | Integration testing, feature validation | Push to `main` or feature branch | None (automatic) |
| **Staging** | Pre-production validation, performance testing | Successful dev deployment | None (automatic with gates) |
| **Production** | Live user traffic | Successful staging deployment | Yes — manual approval |

## Promotion Gates

### Dev → Staging

All of the following must pass before promotion to staging:

- [ ] CI pipeline passes (lint, build, test, security scan)
- [ ] Container image built and pushed to registry
- [ ] Image vulnerability scan reports no critical findings
- [ ] Dev environment smoke tests pass
- [ ] No open P0/P1 bugs linked to the release

### Staging → Production

All of the following must pass before promotion to production:

- [ ] All staging smoke tests pass
- [ ] Performance/load tests meet baseline thresholds (if applicable)
- [ ] Security scan of deployed configuration passes
- [ ] Rollback procedure has been reviewed and is current
- [ ] Database migration backward-compatibility confirmed
- [ ] Manual approval from designated reviewer(s)
- [ ] Deployment window is within the allowed schedule

## GitHub Actions Environment Configuration

Configure these settings in **Repository → Settings → Environments**:

### Staging Environment

```yaml
# In your workflow file
deploy-staging:
  environment:
    name: staging
    url: https://staging.example.com
  # GitHub environment protection rules (set in repo settings):
  #   - Required reviewers: none
  #   - Wait timer: 0 minutes
  #   - Deployment branches: main only
```

### Production Environment

```yaml
deploy-production:
  environment:
    name: production
    url: https://app.example.com
  # GitHub environment protection rules (set in repo settings):
  #   - Required reviewers: 1+ (service owner or tech lead)
  #   - Wait timer: 5 minutes (cool-down after staging)
  #   - Deployment branches: main only
```

## Artifact Promotion Rules

- **Same artifact, different config** — the container image or build artifact deployed to staging is the exact same artifact deployed to production. Only environment-specific configuration (connection strings, feature flags, scaling parameters) changes.
- **No rebuilds** — never rebuild the artifact for a different environment. If the artifact needs to change, start the pipeline from the beginning.
- **Tagging** — tag promoted artifacts with the environment name in addition to the version tag:
  - After staging deployment: `v1.2.3-staging`
  - After production deployment: `v1.2.3-production`

## Configuration Management

| Configuration Type | Storage | Example |
|---|---|---|
| Non-sensitive settings | Environment-specific config files or variables | API URLs, feature flags, log levels |
| Secrets | Secret store (GitHub Secrets, Key Vault, etc.) | Database passwords, API keys, tokens |
| Infrastructure parameters | IaC variable files per environment | Replica count, SKU, region |

## Monitoring During Promotion

After each environment promotion, monitor the following for at least 15 minutes before considering the deployment stable:

- Error rate (should not exceed baseline by more than 5%)
- Request latency (p50, p95, p99 should remain within SLO)
- Health check status (all instances reporting healthy)
- Log volume and error patterns (no new error categories)

## Rollback Triggers

Automatically trigger rollback (or alert for manual rollback) if any of the following occur within the monitoring window:

- Error rate exceeds 2x baseline for 5+ minutes
- Health checks fail on more than 25% of instances
- Deployment-blocking alert fires (defined in observability configuration)
- Smoke tests fail in the target environment

When rollback is triggered, follow the rollback runbook: `skills/devops/rollback-runbook-template.md`.
