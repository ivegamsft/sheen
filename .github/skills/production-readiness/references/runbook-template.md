# Incident Response Runbook Template

## High Error Rate Runbook

### Symptoms

- Error rate > 1% for > 5 minutes

### Immediate Actions (0–5 min)

1. Create incident ticket
2. Start war room
3. Check recent deployments
4. Check metrics dashboard

### Diagnosis (5–15 min)

1. Check error logs
2. Check error rates by endpoint
3. Check database performance

### Quick Fixes

- Recent deploy: `kubectl rollout undo deployment/<name>`
- Database timeout: restart connection pool
- Cache miss: clear and warm cache

### Escalation

If not resolved in 15 minutes, page VP Engineering.

### Post-Mortem

- Schedule within 24 hours
- Document root cause
- Create prevention tickets
