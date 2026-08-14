## Threat Detection Patterns

### 1. Authentication Attack Detection

**Azure AD Authentication Anomalies (KQL):**
```kusto
SigninLogs
| where TimeGenerated > ago(24h)
| where ResultType != 0  // Failed logins only
| summarize FailureCount = count() by UserPrincipalName, IPAddress
| where FailureCount > 10
| project UserPrincipalName, IPAddress, FailureCount, 
  Alert = strcat("Brute force detected: ", UserPrincipalName, " from ", IPAddress)
```

**Kubernetes API Server Attack Detection:**
```bash
#!/bin/bash
# detect-k8s-api-attacks.sh

# Extract API audit logs from last hour
kubectl logs -n kube-system -l component=kube-apiserver --tail=10000 | \
  jq -r 'select(.verb=="create" and .objectRef.resource=="pods" and .stage=="RequestReceived")' | \
  jq -s 'group_by(.user.username) | map({user: .[0].user.username, count: length}) | 
    sort_by(.count) | reverse | .[0:5]' > /tmp/pod_creation_ranking.json

# Alert if single user creates >50 pods/hour
jq '.[] | select(.count > 50) | .user' /tmp/pod_creation_ranking.json | while read user; do
  echo "ALERT: Possible privilege escalation by $user (>50 pod creations)"
  # Send to SIEM
  curl -X POST https://siem.example.com/api/events \
    -H "Authorization: Bearer $SIEM_TOKEN" \
    -d "{'severity': 'high', 'alert': 'K8s privilege escalation attempt by $user'}"
done
```

### 2. Data Access Anomalies

**Detecting Unusual Database Queries:**
```sql
-- Identify queries reading unusually large result sets
SELECT
  user,
  query,
  rows_returned,
  execution_time_ms,
  NOW() as alert_time
FROM query_audit_log
WHERE timestamp > NOW() - INTERVAL 1 HOUR
AND rows_returned > (
  SELECT AVG(rows_returned) + (STDDEV_POP(rows_returned) * 3)
  FROM query_audit_log
  WHERE timestamp > NOW() - INTERVAL 30 DAY
  AND user = query_audit_log.user
)
ORDER BY rows_returned DESC
LIMIT 100;
```

**Azure Blob Storage Anomalies:**
```kusto
StorageBlobLogs
| where TimeGenerated > ago(1h)
| where OperationName in ("GetBlob", "ListBlobs")
| summarize 
    TotalRead_GB = sum(ContentLengthBytes) / (1024*1024*1024),
    RequestCount = count() 
    by UserPrincipalName, ClientIpAddress
| where TotalRead_GB > 10  // Threshold: 10GB per hour
| project UserPrincipalName, ClientIpAddress, TotalRead_GB, RequestCount,
  Alert = "Unusual bulk data access"
```

### 3. Privilege Escalation Detection

**RBAC Role Change Detection:**
```yaml
apiVersion: audit.k8s.io/v1
kind: Policy
rules:
  - level: RequestResponse
    verbs: ["create", "update", "patch", "delete"]
    resources: ["clusterroles", "clusterrolebindings", "roles", "rolebindings"]
    omitStages: ["RequestReceived"]

---
# Post-audit log analysis
apiVersion: v1
kind: ConfigMap
metadata:
  name: rbac-alert-rules
  namespace: kube-system
data:
  detect_rbac_changes.sh: |
    #!/bin/bash
    # Alert if non-admin modifies admin roles
    jq -r 'select(
      (.verb == "patch" or .verb == "update") and
      (.objectRef.resource == "clusterroles" or .objectRef.resource == "roles") and
      .user.username != "system:admin"
    ) | .user.username + " modified " + .objectRef.resource' audit-log.json | \
    while read entry; do
      echo "ALERT: Unauthorized RBAC modification: $entry"
    done
```

---
