# CIDR Allocation Template

Use this template to record and validate all VNet and subnet address spaces before provisioning.
Fill in the `Address Space` and `Purpose` columns; verify there are no overlapping ranges.

## VNet Address Spaces

| VNet Name | Environment | Region | Address Space | Purpose |
|---|---|---|---|---|
| hub-vnet | Shared | East US 2 | 10.0.0.0/16 | Hub — gateway, firewall, DNS, Bastion |
| spoke-app-prod | Production | East US 2 | 10.1.0.0/16 | App workload — production |
| spoke-app-nonprod | Non-prod | East US 2 | 10.2.0.0/16 | App workload — dev/test |
| spoke-data-prod | Production | East US 2 | 10.3.0.0/16 | Data platform — production |
| spoke-shared | Shared | East US 2 | 10.4.0.0/16 | Shared services — monitoring, management |
| hub-vnet-dr | Shared | West US 3 | 10.10.0.0/16 | DR hub — failover region |

> **Rule:** No two VNets may share overlapping address spaces, including on-premises ranges.
> On-premises range(s): `192.168.0.0/16` — document all here and verify no overlap.

## Subnet Allocations — Hub VNet (10.0.0.0/16)

| Subnet Name | CIDR | Usable IPs | Purpose | NSG | Route Table |
|---|---|---|---|---|---|
| GatewaySubnet | 10.0.0.0/27 | 27 | VPN / ER gateway (no NSG allowed) | None | None |
| AzureFirewallSubnet | 10.0.1.0/26 | 62 | Azure Firewall (no NSG allowed) | None | None |
| AzureFirewallManagementSubnet | 10.0.1.64/26 | 62 | Firewall forced-tunnel mgmt | None | None |
| dns-inbound-subnet | 10.0.2.0/28 | 11 | DNS Resolver inbound endpoint | nsg-dns | None |
| dns-outbound-subnet | 10.0.2.16/28 | 11 | DNS Resolver outbound endpoint | None | None |
| AzureBastionSubnet | 10.0.3.0/26 | 62 | Azure Bastion (no UDR allowed) | nsg-bastion | None |
| mgmt-subnet | 10.0.4.0/24 | 251 | Jump servers, monitoring agents | nsg-mgmt | rt-hub |

## Subnet Allocations — Spoke App Prod (10.1.0.0/16)

| Subnet Name | CIDR | Usable IPs | Purpose | NSG | Route Table |
|---|---|---|---|---|---|
| frontend-subnet | 10.1.1.0/24 | 251 | App Service / AKS frontend | nsg-frontend | rt-spoke |
| backend-subnet | 10.1.2.0/24 | 251 | API layer / microservices | nsg-backend | rt-spoke |
| integration-subnet | 10.1.3.0/24 | 251 | VNet integration for App Service | nsg-integration | rt-spoke |
| pe-subnet | 10.1.4.0/24 | 251 | Private endpoints (PaaS) | nsg-pe | None |

## Subnet Allocations — Spoke Data Prod (10.3.0.0/16)

| Subnet Name | CIDR | Usable IPs | Purpose | NSG | Route Table |
|---|---|---|---|---|---|
| db-subnet | 10.3.1.0/24 | 251 | SQL MI / PostgreSQL Flexible | nsg-db | rt-spoke |
| analytics-subnet | 10.3.2.0/24 | 251 | Synapse / Databricks | nsg-analytics | rt-spoke |
| pe-subnet | 10.3.3.0/24 | 251 | Private endpoints (PaaS) | nsg-pe | None |

## Reserved Ranges

| Range | Reserved For | Do Not Use |
|---|---|---|
| 10.0.0.0/8 | All Azure VNets | — |
| 192.168.0.0/16 | On-premises corporate | Do not allocate in Azure |
| 172.16.0.0/12 | On-premises branch offices | Do not allocate in Azure |
| 169.254.0.0/16 | Azure link-local (APIPA) | Reserved by platform |
| 168.63.129.16/32 | Azure platform (health probes, DNS) | Reserved by platform |

## CIDR Sizing Guide

| Prefix | Usable Host IPs | Recommended For |
|---|---|---|
| /28 | 11 | DNS resolver endpoints, small service subnets |
| /27 | 27 | GatewaySubnet, small infra subnets |
| /26 | 59 | AzureFirewallSubnet, AzureBastionSubnet |
| /25 | 123 | Medium workload subnets (128 total − 5 Azure-reserved = 123) |
| /24 | 251 | Standard workload subnets (256 total − 5 Azure-reserved = 251) |
| /23 | 507 | Large workload subnets (512 total − 5 Azure-reserved = 507) |
| /16 | 65,531 | VNet address space |
