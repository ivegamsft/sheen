## Monitoring & Metrics

**Key SOC Metrics:**
```promql
# Alert response time
histogram_quantile(0.95,
  rate(alert_response_time_seconds[5m])
)

# False positive rate
sum(rate(alert_dismissed_false_positive[1d])) /
sum(rate(alert_total[1d]))

# Mean time to detect (MTTD)
avg(alert_time_to_escalation_seconds) / 60

# Patch compliance
count(system{patched="true", asset_criticality="high"}) /
count(system{asset_criticality="high"})

# Incident resolution rate
sum(rate(incident_resolved[1w])) /
sum(rate(incident_created[1w]))
```

---
