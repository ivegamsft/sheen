# Rollback Runbook Template

Use this template to document the rollback procedure for each deployable service. Fill in the placeholders and keep this runbook up to date with every deployment.

## Service Information

| Field | Value |
|---|---|
| **Service name** | `<service-name>` |
| **Repository** | `<org/repo>` |
| **Deployment target** | `<e.g., AKS cluster, App Service, Cloud Run>` |
| **Current version** | `<version or commit SHA>` |
| **Previous version** | `<version or commit SHA to rollback to>` |
| **Runbook last tested** | `<date>` |

## When to Rollback

Initiate a rollback when any of the following conditions are met after deployment:

- Error rate exceeds the SLO threshold for more than 5 minutes
- Health check endpoints return unhealthy status
- Critical user flows are broken (verified by smoke tests or user reports)
- Deployment pipeline reports a failed deployment that left the environment in a degraded state

**Decision rule:** If the issue cannot be diagnosed and a fix-forward deployed within 15 minutes, rollback immediately.

## Rollback Steps

### 1. Notify the Team

- Post in the incident channel: `Rolling back <service-name> from <current-version> to <previous-version>. Reason: <brief description>.`
- Tag the on-call engineer and service owner.

### 2. Execute Rollback

Choose the method that matches your deployment strategy:

#### Option A: Re-deploy Previous Artifact

```bash
# Trigger deployment of the previous known-good artifact
# Adapt to your CI/CD system and deployment tooling

# Example: GitHub Actions workflow dispatch
gh workflow run deploy.yml \
  --ref main \
  -f image-tag=<previous-version> \
  -f environment=production

# Example: Kubernetes rollback
kubectl rollout undo deployment/<service-name> \
  --namespace <namespace>

# Example: Azure App Service slot swap (swap back to previous slot)
az webapp deployment slot swap \
  --name <app-name> \
  --resource-group <rg-name> \
  --slot staging \
  --target-slot production
```

#### Option B: Revert the Merge Commit

```bash
# If the deployment is triggered by a merge to main
git revert <merge-commit-sha> --mainline 1
git push origin main
# CI/CD pipeline will deploy the reverted state
```

### 3. Verify Rollback

- [ ] Health check endpoints return healthy status
- [ ] Error rate has returned to pre-deployment baseline
- [ ] Key user flows are functional (run smoke tests)
- [ ] Logs confirm the previous version is serving traffic
- [ ] Monitoring dashboards show normal behavior

### 4. Rollback Database Changes (If Applicable)

> ⚠️ Only perform database rollback if migrations are not backward-compatible. Prefer backward-compatible migrations that do not require rollback.

```bash
# Example: Run the down migration
# Adapt to your migration tool (Flyway, Alembic, EF Migrations, etc.)
<migration-tool> migrate down --to <previous-migration-version>
```

- [ ] Verify data integrity after migration rollback
- [ ] Confirm application functions correctly with the rolled-back schema

### 5. Post-Rollback

- [ ] Update the incident channel with rollback status and verification results
- [ ] File a post-incident issue:

```bash
gh issue create \
  --title "[Post-Incident] <service-name> rollback on <date>" \
  --label "incident,devops" \
  --body "## Incident Summary

**Service:** <service-name>
**Rolled back from:** <current-version>
**Rolled back to:** <previous-version>
**Duration of impact:** <time>
**Users affected:** <estimate>

### Root Cause
<description>

### Timeline
- <HH:MM> Deployment started
- <HH:MM> Issue detected
- <HH:MM> Rollback initiated
- <HH:MM> Rollback verified

### Remediation
- [ ] <action item 1>
- [ ] <action item 2>

### Lessons Learned
<what can be improved>"
```

## Rollback Testing Schedule

Test the rollback procedure in a non-production environment at least once every 30 days. Record the test date in the Service Information table above.

| Date | Environment | Result | Tester |
|---|---|---|---|
| `<date>` | `<staging>` | `<pass/fail>` | `<name>` |
