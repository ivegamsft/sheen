# NSG Rule Matrix Template

Use this template to define inbound and outbound NSG rules for each subnet tier.
Priority values must be unique per direction within an NSG. Lower numbers = higher priority.
Azure default rules start at priority 65000 — custom rules should be ≤ 4096.

## NSG: nsg-frontend (App Tier)

### Inbound Rules

| Priority | Name | Source | Source Port | Destination | Dest Port | Protocol | Action | Purpose |
|---|---|---|---|---|---|---|---|---|
| 100 | allow-https-from-agw | Application Gateway subnet CIDR | * | 10.1.1.0/24 | 443 | TCP | Allow | HTTPS from App Gateway |
| 110 | allow-http-from-agw | Application Gateway subnet CIDR | * | 10.1.1.0/24 | 80 | TCP | Allow | HTTP redirect from App Gateway |
| 200 | allow-azure-lb | AzureLoadBalancer | * | * | * | * | Allow | Required Azure LB health probes |
| 900 | deny-all-inbound | * | * | * | * | * | Deny | Explicit default deny |

### Outbound Rules

| Priority | Name | Source | Source Port | Destination | Dest Port | Protocol | Action | Purpose |
|---|---|---|---|---|---|---|---|---|
| 100 | allow-to-backend | 10.1.1.0/24 | * | 10.1.2.0/24 | 8080 | TCP | Allow | Frontend → backend API |
| 110 | allow-to-keyvault | 10.1.1.0/24 | * | 10.1.4.0/24 | 443 | TCP | Allow | Key Vault private endpoint |
| 200 | allow-to-firewall | 10.1.1.0/24 | * | 10.0.1.0/26 | * | * | Allow | Internet-bound via hub firewall |
| 900 | deny-all-outbound | * | * | * | * | * | Deny | Explicit default deny |

---

## NSG: nsg-backend (API Tier)

### Inbound Rules

| Priority | Name | Source | Source Port | Destination | Dest Port | Protocol | Action | Purpose |
|---|---|---|---|---|---|---|---|---|
| 100 | allow-from-frontend | 10.1.1.0/24 | * | 10.1.2.0/24 | 8080 | TCP | Allow | API calls from frontend tier |
| 110 | allow-from-integration | 10.1.3.0/24 | * | 10.1.2.0/24 | 8080 | TCP | Allow | VNet-integrated App Service |
| 200 | allow-azure-lb | AzureLoadBalancer | * | * | * | * | Allow | LB health probes |
| 900 | deny-all-inbound | * | * | * | * | * | Deny | Explicit default deny |

### Outbound Rules

| Priority | Name | Source | Source Port | Destination | Dest Port | Protocol | Action | Purpose |
|---|---|---|---|---|---|---|---|---|
| 100 | allow-to-pe | 10.1.2.0/24 | * | 10.1.4.0/24 | 443 | TCP | Allow | PaaS private endpoints |
| 110 | allow-to-db-pe | 10.1.2.0/24 | * | 10.3.3.0/24 | 1433 | TCP | Allow | SQL via private endpoint |
| 200 | allow-to-firewall | 10.1.2.0/24 | * | 10.0.1.0/26 | * | * | Allow | Internet-bound via hub firewall |
| 900 | deny-all-outbound | * | * | * | * | * | Deny | Explicit default deny |

---

## NSG: nsg-pe (Private Endpoint Subnets)

> Private endpoint subnets do not enforce NSG rules on the endpoint NIC itself,
> but NSG rules on the *source* subnet govern traffic reaching private endpoints.
> Apply the following NSG to restrict which subnets can initiate connections.

### Inbound Rules

| Priority | Name | Source | Source Port | Destination | Dest Port | Protocol | Action | Purpose |
|---|---|---|---|---|---|---|---|---|
| 100 | allow-from-backend | 10.1.2.0/24 | * | 10.1.4.0/24 | 443 | TCP | Allow | Backend → PaaS endpoints |
| 110 | allow-from-hub-mgmt | 10.0.4.0/24 | * | 10.1.4.0/24 | 443 | TCP | Allow | Management access |
| 900 | deny-all-inbound | * | * | * | * | * | Deny | Explicit default deny |

### Outbound Rules

| Priority | Name | Source | Source Port | Destination | Dest Port | Protocol | Action | Purpose |
|---|---|---|---|---|---|---|---|---|
| 100 | allow-to-azure-services | 10.1.4.0/24 | * | AzureCloud | 443 | TCP | Allow | PaaS control plane |
| 900 | deny-all-outbound | * | * | * | * | * | Deny | Explicit default deny |

---

## NSG: nsg-db (Database Tier)

### Inbound Rules

| Priority | Name | Source | Source Port | Destination | Dest Port | Protocol | Action | Purpose |
|---|---|---|---|---|---|---|---|---|
| 100 | allow-sql-from-backend | 10.1.2.0/24 | * | 10.3.1.0/24 | 1433 | TCP | Allow | SQL from app backend |
| 110 | allow-pg-from-backend | 10.1.2.0/24 | * | 10.3.1.0/24 | 5432 | TCP | Allow | PostgreSQL from app backend |
| 120 | allow-from-hub-mgmt | 10.0.4.0/24 | * | 10.3.1.0/24 | 1433,5432 | TCP | Allow | DBA access from management |
| 200 | allow-azure-lb | AzureLoadBalancer | * | * | * | * | Allow | LB health probes |
| 900 | deny-all-inbound | * | * | * | * | * | Deny | Explicit default deny |

### Outbound Rules

| Priority | Name | Source | Source Port | Destination | Dest Port | Protocol | Action | Purpose |
|---|---|---|---|---|---|---|---|---|
| 100 | allow-to-azure-services | 10.3.1.0/24 | * | AzureCloud | 443 | TCP | Allow | Managed service heartbeats |
| 900 | deny-all-outbound | * | * | * | * | * | Deny | Explicit default deny |

---

## NSG: nsg-bastion (AzureBastionSubnet)

> Azure Bastion requires specific ports. Do not modify the required rules.

### Inbound Rules

| Priority | Name | Source | Source Port | Destination | Dest Port | Protocol | Action | Purpose |
|---|---|---|---|---|---|---|---|---|
| 100 | allow-https-inbound | Internet | * | * | 443 | TCP | Allow | Client HTTPS to Bastion |
| 110 | allow-gateway-manager | GatewayManager | * | * | 443 | TCP | Allow | Azure Gateway Manager |
| 120 | allow-azure-lb | AzureLoadBalancer | * | * | 443 | TCP | Allow | LB health probes |
| 130 | allow-bastion-host-comms | VirtualNetwork | * | VirtualNetwork | 8080,5701 | * | Allow | Bastion host communication |
| 900 | deny-all-inbound | * | * | * | * | * | Deny | Explicit default deny |

### Outbound Rules

| Priority | Name | Source | Source Port | Destination | Dest Port | Protocol | Action | Purpose |
|---|---|---|---|---|---|---|---|---|
| 100 | allow-ssh-rdp-to-vms | * | * | VirtualNetwork | 22,3389 | TCP | Allow | SSH/RDP to target VMs |
| 110 | allow-azure-cloud | * | * | AzureCloud | 443 | TCP | Allow | Bastion diagnostics |
| 120 | allow-bastion-host-comms | * | * | VirtualNetwork | 8080,5701 | * | Allow | Bastion host communication |
| 130 | allow-session-info | * | * | Internet | 80 | TCP | Allow | Certificate revocation checks |
| 900 | deny-all-outbound | * | * | * | * | * | Deny | Explicit default deny |

---

## Azure Firewall Policy — Network Rule Collections

| Collection Name | Priority | Action | Rule Name | Source | Dest | Protocol | Ports | Purpose |
|---|---|---|---|---|---|---|---|---|
| allow-hub-to-azure | 100 | Allow | allow-azure-services | 10.0.0.0/8 | AzureCloud | TCP | 443 | Azure management plane |
| allow-spoke-internet | 200 | Allow | allow-https-egress | 10.1.0.0/8 | * | TCP | 443 | HTTPS internet egress |
| allow-spoke-internet | 200 | Allow | allow-ntp | 10.0.0.0/8 | * | UDP | 123 | NTP time sync |
| deny-all | 65000 | Deny | deny-all | * | * | Any | * | Catch-all deny |

## Azure Firewall Policy — Application Rule Collections

| Collection Name | Priority | Action | Rule Name | Source | Target FQDNs | Protocol | Purpose |
|---|---|---|---|---|---|---|---|
| allow-windows-update | 100 | Allow | windows-update | 10.0.0.0/8 | `*.update.microsoft.com`, `*.windowsupdate.com` | Https:443 | OS patching |
| allow-azure-mgmt | 110 | Allow | azure-mgmt | 10.0.0.0/8 | `management.azure.com`, `login.microsoftonline.com` | Https:443 | ARM & AAD |
| allow-container-registries | 120 | Allow | acr | 10.0.0.0/8 | `*.azurecr.io`, `mcr.microsoft.com` | Https:443 | Container images |

## NSG Authoring Notes

- Use **service tags** (`AzureCloud`, `AzureLoadBalancer`, `GatewayManager`) instead of explicit IP ranges for Azure platform sources.
- Use **Application Security Groups (ASGs)** for workloads with many instances to avoid per-IP rule maintenance.
- Enable **NSG Flow Logs** to a Storage Account and route to Log Analytics for diagnostics.
- Review rules against the [Azure NSG limits](https://learn.microsoft.com/azure/azure-resource-manager/management/azure-subscription-service-limits#networking-limits): max 1,000 rules per NSG.
