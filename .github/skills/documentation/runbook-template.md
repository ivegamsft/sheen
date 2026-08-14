# Operational Runbook Template

Use this template for operational runbooks that guide on-call engineers through incident response, maintenance procedures, or routine operational tasks.

---

# Runbook: <Title>

- **Service:** <service or component name>
- **Owner:** <team or individual>
- **Last updated:** <YYYY-MM-DD>
- **Review cadence:** <e.g., quarterly>

## Overview

<1–2 sentences describing what this runbook covers and when to use it.>

## Trigger

<What condition or alert triggers this runbook?>

- Alert name: `<alert name or monitoring rule>`
- Symptoms: <what the user or operator observes>
- Dashboard: <link to relevant monitoring dashboard>

## Prerequisites

- [ ] Access to <system/tool>
- [ ] Permissions: <required role or access level>
- [ ] Tools installed: <CLI tools, SDKs, etc.>

## Diagnosis

Steps to confirm the issue and understand its scope:

1. <Check service health or status endpoint>
   ```bash
   <diagnostic command>
   ```
2. <Review logs for error patterns>
   ```bash
   <log query command>
   ```
3. <Check dependent services>
   ```bash
   <dependency check command>
   ```

**Expected output when healthy:** <describe normal state>
**Indicators of the problem:** <describe what to look for>

## Resolution Steps

### Step 1: <Action title>

<Detailed instructions for the first remediation step.>

```bash
<command>
```

**Expected result:** <what should happen>

### Step 2: <Action title>

<Detailed instructions for the next step.>

```bash
<command>
```

**Expected result:** <what should happen>

### Step 3: Verify Resolution

Confirm the issue is resolved:

```bash
<verification command>
```

- [ ] Service health check passes
- [ ] Error rate returns to baseline
- [ ] Affected users can confirm resolution

## Rollback

If the resolution steps make things worse:

1. <Rollback step 1>
   ```bash
   <rollback command>
   ```
2. <Rollback step 2>
3. Escalate to <team or person> if rollback does not restore service

## Escalation

| Condition | Escalate To | Contact |
|---|---|---|
| Issue not resolved in <N> minutes | <Team or person> | <contact method> |
| Data loss suspected | <Team or person> | <contact method> |
| Customer-facing outage | <Incident commander> | <contact method> |

## Post-Incident

After resolution:

- [ ] Update incident timeline
- [ ] File post-incident review issue
- [ ] Update this runbook if steps were incorrect or incomplete
- [ ] Communicate resolution to stakeholders

## Related Resources

- <Link to architecture diagram>
- <Link to monitoring dashboard>
- <Link to related runbook>
- <Link to ADR if applicable>
