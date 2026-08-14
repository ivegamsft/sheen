# Hub-Spoke Topology Template

Use this template to document an Azure hub-spoke VNet topology as a Mermaid diagram.
Replace placeholder names and CIDR ranges with values specific to the workload.

## Mermaid Diagram

```mermaid
graph TD
    subgraph Hub["Hub VNet (10.0.0.0/16)"]
        GW["VPN / ExpressRoute Gateway\nGatewaySubnet 10.0.0.0/27"]
        FW["Azure Firewall\nAzureFirewallSubnet 10.0.1.0/26"]
        DNS["Azure Private DNS Resolver\nDNS Inbound 10.0.2.0/28\nDNS Outbound 10.0.2.16/28"]
        BAS["Azure Bastion\nAzureBastionSubnet 10.0.3.0/26"]
    end

    subgraph Spoke1["Spoke 1 — App Workload (10.1.0.0/16)"]
        APP["App Tier\n10.1.1.0/24"]
        API["API Tier\n10.1.2.0/24"]
        PE1["Private Endpoints\n10.1.3.0/24"]
    end

    subgraph Spoke2["Spoke 2 — Data Platform (10.2.0.0/16)"]
        DB["Database Tier\n10.2.1.0/24"]
        PE2["Private Endpoints\n10.2.2.0/24"]
    end

    subgraph Spoke3["Spoke 3 — Shared Services (10.3.0.0/16)"]
        MGMT["Management Tier\n10.3.1.0/24"]
        MON["Monitoring Tier\n10.3.2.0/24"]
    end

    OnPrem["On-Premises Network\n192.168.0.0/16"] -- "ExpressRoute / VPN" --> GW

    Hub <--> |VNet Peering| Spoke1
    Hub <--> |VNet Peering| Spoke2
    Hub <--> |VNet Peering| Spoke3

    APP --> FW
    API --> FW
    DB  --> FW
```

## Peering Configuration

| Peering | Allow forwarded traffic | Allow gateway transit | Use remote gateways |
|---|---|---|---|
| Hub → Spoke 1 | Yes | Yes | No |
| Spoke 1 → Hub | Yes | No | Yes |
| Hub → Spoke 2 | Yes | Yes | No |
| Spoke 2 → Hub | Yes | No | Yes |
| Hub → Spoke 3 | Yes | Yes | No |
| Spoke 3 → Hub | Yes | No | Yes |

> **Note:** Enable `Allow gateway transit` only on the hub side of each peering.
> Enable `Use remote gateways` only on spoke sides to route through the hub gateway.

## Design Decisions

| Decision | Choice | Rationale |
|---|---|---|
| Internet egress | Azure Firewall in hub | Centralised inspection and logging |
| DNS resolution | Azure Private DNS Resolver | Supports on-premises conditional forwarding |
| Bastion | Hub-deployed Azure Bastion | Single jump host for all spokes |
| Spoke isolation | No spoke-to-spoke peering | All cross-spoke traffic via hub firewall |
