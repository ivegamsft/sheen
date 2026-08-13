# Azure Networking — Guardrails and Agent Pairing

## Guardrails

- Do not allocate overlapping CIDR ranges across VNets — validate all address spaces
  before committing.
- Always route internet-bound traffic through Azure Firewall or an NVA in the hub;
  do not leave spoke subnets with direct internet egress.
- Private endpoint DNS zones must be linked to every VNet that needs name resolution
  — document each link explicitly.
- NSG rules must include both allow and explicit deny entries; do not rely solely on
  default deny.
- Do not use overly broad source CIDRs such as `0.0.0.0/0` in NSG allow rules without
  a compensating Firewall or WAF layer.
- Scope this skill to network-layer design. For identity/RBAC, defer to the `security`
  skill; for IaC authoring, defer to `devops` or the `terraform`/`bicep` instructions.

## Agent Pairing

This skill is designed to work alongside the `solution-architect` and `devops-engineer`
agents. The `solution-architect` agent drives the overall design; this skill provides
the network-layer reference patterns and templates.

For IaC output (Terraform or Bicep), pair with the `devops-engineer` agent and the
`terraform` or `bicep` instruction files.

## External References

- [Hub-spoke network topology on Azure](https://learn.microsoft.com/azure/architecture/reference-architectures/hybrid-networking/hub-spoke)
- [Azure Private Endpoint overview](https://learn.microsoft.com/azure/private-link/private-endpoint-overview)
- [Azure Private DNS zones](https://learn.microsoft.com/azure/dns/private-dns-overview)
- [Azure Firewall overview](https://learn.microsoft.com/azure/firewall/overview)
- [Azure Virtual Network limits](https://learn.microsoft.com/azure/azure-resource-manager/management/azure-subscription-service-limits#azure-resource-manager-virtual-networking-limits)
- [Network security groups](https://learn.microsoft.com/azure/virtual-network/network-security-groups-overview)
- [User-defined routes overview](https://learn.microsoft.com/azure/virtual-network/virtual-networks-udr-overview)
