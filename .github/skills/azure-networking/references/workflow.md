# Azure Networking — Design Workflow

1. **Assess connectivity requirements** — identify hybrid (ExpressRoute/VPN),
   multi-region, and internet-facing needs; document workload tiers and
   data-classification zones.

2. **Generate hub-spoke VNet topology** — define the hub VNet (firewall, gateway,
   DNS) and spoke VNets (per workload/environment); allocate CIDR ranges using the
   CIDR allocation template.

3. **Configure private endpoints and Private DNS zones** — map each PaaS service to
   its private endpoint and DNS zone using the private-endpoint DNS zone mapping
   template.

4. **Produce NSG rules and Azure Firewall policy** — define inbound/outbound rules
   per subnet tier using the NSG rule matrix template; produce Azure Firewall
   application and network rule collections.

5. **Generate route tables (UDR)** — create UDR entries for forced tunneling to hub
   firewall; document any asymmetric routing exceptions.

6. **Validate against Azure limits and best practices** — check VNet address-space
   limits, peering constraints, DNS resolution chain, and private endpoint DNS
   override precedence.
