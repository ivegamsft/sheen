# Private Endpoint DNS Zone Mapping Template

Use this template to document every PaaS service that requires a private endpoint,
its associated Azure Private DNS zone, and the VNets that must be linked to that zone.

## Mapping Table

| PaaS Service | Private Endpoint Sub-resource | Private DNS Zone | DNS Zone Link VNets | Notes |
|---|---|---|---|---|
| Azure Storage (Blob) | `blob` | `privatelink.blob.core.windows.net` | hub, spoke-app-prod, spoke-data-prod | One zone per service type |
| Azure Storage (File) | `file` | `privatelink.file.core.windows.net` | hub, spoke-app-prod | |
| Azure Storage (Queue) | `queue` | `privatelink.queue.core.windows.net` | hub, spoke-app-prod | |
| Azure Storage (Table) | `table` | `privatelink.table.core.windows.net` | hub, spoke-app-prod | |
| Azure Storage (DFS) | `dfs` | `privatelink.dfs.core.windows.net` | hub, spoke-data-prod | ADLS Gen2 |
| Azure SQL Database | `sqlServer` | `privatelink.database.windows.net` | hub, spoke-app-prod, spoke-data-prod | |
| Azure Database for PostgreSQL (Flexible) | `postgresqlServer` | `privatelink.postgres.database.azure.com` | hub, spoke-data-prod | |
| Azure Database for MySQL (Flexible) | `mysqlServer` | `privatelink.mysql.database.azure.com` | hub, spoke-data-prod | |
| Azure Cosmos DB | `Sql` | `privatelink.documents.azure.com` | hub, spoke-data-prod | Sub-resource varies by API |
| Azure Key Vault | `vault` | `privatelink.vaultcore.azure.net` | hub, all spokes | Every workload VNet |
| Azure Container Registry | `registry` | `privatelink.azurecr.io` | hub, spoke-app-prod | |
| Azure Kubernetes Service API | `management` | `privatelink.<region>.azmk8s.io` | hub, spoke-app-prod | Region-specific zone name |
| Azure Service Bus | `namespace` | `privatelink.servicebus.windows.net` | hub, spoke-app-prod | |
| Azure Event Hubs | `namespace` | `privatelink.servicebus.windows.net` | hub, spoke-app-prod | Shares DNS zone namespace with Service Bus; requires its own separate private endpoint |
| Azure Event Grid | `topic` / `domain` | `privatelink.eventgrid.azure.net` | hub, spoke-app-prod | |
| Azure App Configuration | `configurationStores` | `privatelink.azconfig.io` | hub, all spokes | |
| Azure Monitor / Log Analytics | `azuremonitor` | `privatelink.monitor.azure.com` | hub, all spokes | Multiple zones required — see note |
| Azure OpenAI | `account` | `privatelink.openai.azure.com` | hub, spoke-app-prod | |
| Azure Cognitive Services | `account` | `privatelink.cognitiveservices.azure.com` | hub, spoke-app-prod | |
| Azure Machine Learning | `amlworkspace` | `privatelink.api.azureml.ms` | hub, spoke-data-prod | Additional notebook zone needed |
| Azure Data Factory | `dataFactory` | `privatelink.datafactory.azure.net` | hub, spoke-data-prod | |
| Azure Synapse Analytics | `Sql` | `privatelink.sql.azuresynapse.net` | hub, spoke-data-prod | Multiple sub-resources |
| Azure Backup (Recovery Services) | `AzureBackup` | `privatelink.<geo>.backup.windowsazure.com` | hub | Geo-specific zone |
| Azure Web App (App Service) | `sites` | `privatelink.azurewebsites.net` | hub, spoke-app-prod | SCM endpoint also needs mapping |
| Azure API Management | `Gateway` | `privatelink.azure-api.net` | hub, spoke-app-prod | |

> **Note — Azure Monitor private link**: Requires multiple DNS zones:
> `privatelink.monitor.azure.com`, `privatelink.oms.opinsights.azure.com`,
> `privatelink.ods.opinsights.azure.com`, `privatelink.agentsvc.azure-automation.net`,
> and `privatelink.blob.core.windows.net`. Link all to every monitoring-capable VNet.

## DNS Resolution Chain

```
On-Premises DNS Server
  └── Conditional forwarder: *.privatelink.* → Azure DNS Resolver Inbound IP
        └── Azure Private DNS Resolver (hub)
              └── Azure DNS (168.63.129.16)
                    └── Private DNS Zone → Private Endpoint NIC IP
```

## VNet DNS Zone Link Checklist

For each Private DNS zone, every VNet that hosts consumers of that service must have a
virtual network link created. Missing links cause resolution to fall back to public DNS.

| Private DNS Zone | hub | spoke-app-prod | spoke-app-nonprod | spoke-data-prod | spoke-shared |
|---|---|---|---|---|---|
| `privatelink.blob.core.windows.net` | ✅ | ✅ | ✅ | ✅ | ✅ |
| `privatelink.vaultcore.azure.net` | ✅ | ✅ | ✅ | ✅ | ✅ |
| `privatelink.database.windows.net` | ✅ | ✅ | ✅ | ✅ | — |
| `privatelink.azurecr.io` | ✅ | ✅ | ✅ | — | — |
| `privatelink.servicebus.windows.net` | ✅ | ✅ | ✅ | — | — |

> Replace `✅` / `—` with actual link status after provisioning.

## Provisioning Notes

- Create all Private DNS zones in a single **hub resource group** to centralise management.
- Use **auto-registration** only for VM DNS records; never enable it on private-endpoint zones.
- If using Terraform, use `azurerm_private_dns_zone` and `azurerm_private_dns_zone_virtual_network_link` resources.
- If using Bicep, use the `Microsoft.Network/privateDnsZones` and `virtualNetworkLinks` child resources.
