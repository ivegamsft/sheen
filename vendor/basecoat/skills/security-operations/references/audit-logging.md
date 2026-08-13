## Audit Logging

### 1. Centralized Log Collection

**ELK Stack Configuration (Filebeat + Elasticsearch):**
```yaml
# filebeat.yml
filebeat.inputs:
- type: log
  enabled: true
  paths:
    - /var/log/auth.log
    - /var/log/audit/audit.log
    - /var/log/kubernetes/*.log
  fields:
    source: "system-logs"
    environment: "production"

- type: container
  enabled: true
  paths:
    - "/var/lib/docker/containers/*/*.log"
  fields:
    source: "container-logs"

processors:
  - add_kubernetes_metadata:
      in_cluster: true
  - add_docker_metadata: {}
  - add_fields:
      target: metadata
      fields:
        region: us-east-1
        account: prod

output.elasticsearch:
  hosts: ["elasticsearch.siem.svc.cluster.local:9200"]
  indices:
    - index: "audit-%{+yyyy.MM.dd}"
      when.contains:
        source: "audit"
    - index: "container-%{+yyyy.MM.dd}"
      when.contains:
        source: "container"

logging.level: info
logging.to_files: true
```

**Log Parsing & Enrichment (Logstash):**
```
input {
  elasticsearch {
    hosts => "elasticsearch:9200"
    index => "raw-logs-*"
  }
}

filter {
  # Parse syslog
  if [source] == "system-logs" {
    grok {
      match => {
        "message" => "%{SYSLOGLINE}"
      }
    }
  }

  # Enrich with threat intelligence
  file {
    include => "/etc/logstash/threat-intel.conf"
  }

  # GeoIP enrichment
  geoip {
    source => "source_ip"
    target => "geoip"
  }

  # Add severity scoring
  if [event_type] == "authentication_failure" {
    mutate {
      add_field => { "severity_score" => 3 }
      add_tag => [ "auth_attack" ]
    }
  }
}

output {
  # Write to separate indices for performance
  elasticsearch {
    hosts => "elasticsearch:9200"
    index => "audit-%{+YYYY.MM.dd}"
    document_type => "_doc"
  }

  # Alert on high-severity events
  if "auth_attack" in [tags] {
    email {
      to => "security-team@example.com"
      subject => "Security Alert: %{alert_name}"
      body => "Severity: %{severity_score}\nDetails: %{message}"
    }
  }
}
```

### 2. Immutable Audit Trail

**Azure Immutable Blob Storage (Terraform):**
```hcl
resource "azurerm_storage_account" "audit" {
  name                     = "auditlogs${random_string.suffix.result}"
  resource_group_name      = azurerm_resource_group.security.name
  location                 = azurerm_resource_group.security.location
  account_tier             = "Standard"
  account_replication_type = "GRS"
  access_tier              = "Cool"

  identity {
    type = "SystemAssigned"
  }

  network_rules {
    default_action = "Deny"
    bypass         = ["AzureServices"]
  }
}

# Enable immutability
resource "azurerm_storage_container_immutability_policy" "audit" {
  storage_account_name          = azurerm_storage_account.audit.name
  container_name                = "audit-logs"
  immutability_policy_until_date = "2034-05-02T00:00:00Z"  # 8 years
  protected_append_writes_enabled = true
}

# Enable versioning for audit trail
resource "azurerm_storage_account_management_policy" "audit" {
  storage_account_id = azurerm_storage_account.audit.id

  rule {
    name    = "DeleteOldVersions"
    enabled = false  # Never delete, just move to archive tier
    
    actions {
      version {
        delete_after_days_since_creation = 2555  # 7 years
      }
      
      snapshot {
        tier_to_archive_after_days_since_creation = 365
      }
    }

    filters {
      blob_types   = ["blockBlob"]
      prefix_match = ["audit/"]
    }
  }
}
```

---
