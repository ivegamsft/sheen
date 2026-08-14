## Secrets Management

### 1. Automated Credential Rotation

**Kubernetes Secret Rotation (CronJob):**
```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: rotate-db-credentials
  namespace: security
spec:
  schedule: "0 2 * * 0"  # Weekly at 2 AM
  jobTemplate:
    spec:
      template:
        spec:
          serviceAccountName: credential-rotator
          containers:
          - name: rotator
            image: registry.example.com/rotator:latest
            env:
            - name: DB_HOST
              value: postgres.default.svc.cluster.local
            - name: VAULT_ADDR
              value: https://vault.example.com
            args:
            - --database=postgres
            - --users=app_user,backup_user
            - --length=32
            - --symbols=true
          restartPolicy: OnFailure
          securityContext:
            runAsNonRoot: true
            readOnlyRootFilesystem: true
```

**Rotation Script (Python):**
```python
import os
import psycopg2
import hvac
import secrets
import string

def rotate_postgres_password(db_user: str):
    """Rotate PostgreSQL user password and store in Vault"""
    
    # Generate new password
    alphabet = string.ascii_letters + string.digits + "!@#$%^&*"
    new_password = ''.join(secrets.choice(alphabet) for i in range(32))
    
    # Connect to PostgreSQL
    conn = psycopg2.connect(
        host=os.getenv("DB_HOST"),
        user=os.getenv("DB_ADMIN_USER"),
        password=os.getenv("DB_ADMIN_PASS")
    )
    cursor = conn.cursor()
    
    try:
        # Update password
        cursor.execute(f"ALTER USER {db_user} WITH PASSWORD %s", (new_password,))
        conn.commit()
        print(f"✓ Password rotated for {db_user}")
        
        # Store in Vault
        client = hvac.Client(url=os.getenv("VAULT_ADDR"))
        client.auth.kubernetes.login(
            role="app-rotation-role",
            jwt=open("/var/run/secrets/kubernetes.io/serviceaccount/token").read()
        )
        
        client.secrets.kv.v2.create_or_update_secret(
            path=f"database/postgres/{db_user}",
            secret_data={
                "username": db_user,
                "password": new_password,
                "connection_string": f"postgresql://{db_user}:{new_password}@{os.getenv('DB_HOST')}/app"
            }
        )
        print(f"✓ Credentials stored in Vault")
        
        # Audit log
        audit_event = {
            "event": "credential_rotation",
            "resource": f"database:postgres:{db_user}",
            "timestamp": datetime.now().isoformat(),
            "status": "success"
        }
        send_audit_event(audit_event)
        
    except Exception as e:
        print(f"✗ Rotation failed: {e}")
        audit_event["status"] = "failed"
        audit_event["error"] = str(e)
        send_audit_event(audit_event)
        raise
    finally:
        cursor.close()
        conn.close()

def send_audit_event(event: dict):
    """Send audit event to SIEM"""
    import requests
    requests.post(
        "https://siem.example.com/api/audit-events",
        json=event,
        headers={"Authorization": f"Bearer {os.getenv('SIEM_TOKEN')}"}
    )
```

### 2. Secret Access Auditing

**Vault Secret Access Logs (HCL):**
```hcl
path "database/data/postgres/*" {
  capabilities = ["read"]
}

path "sys/leases/lookup" {
  capabilities = ["update"]
}

path "auth/token/renew-self" {
  capabilities = ["update"]
}

# Audit all database access
audit {
  file {
    path = "/var/log/vault-audit.log"
  }

  syslog {
    tag      = "vault"
    facility = "LOCAL7"
  }
}

# Vault audit query (after enabling)
policy "audit-db-access" {
  rules {
    # Alert if same user accesses multiple database credentials in 5 min
    query = """
      SELECT user_identity, COUNT(*) as access_count 
      FROM vault_audit_log 
      WHERE timestamp > NOW() - INTERVAL 5 MINUTE 
      AND path LIKE 'database/data/%'
      GROUP BY user_identity 
      HAVING access_count > 3
    """
    threshold = 1
    severity  = "high"
  }
}
```

---
