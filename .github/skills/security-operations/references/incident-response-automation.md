## Incident Response Automation

**Alert Triage & Escalation (Python):**
```python
import asyncio
import httpx
from enum import Enum
from dataclasses import dataclass

class Severity(Enum):
    CRITICAL = 1
    HIGH = 2
    MEDIUM = 3
    LOW = 4

@dataclass
class SecurityAlert:
    id: str
    alert_name: str
    severity: Severity
    source_ip: str
    target_resource: str
    timestamp: str

class IncidentResponder:
    def __init__(self, siem_url: str, ticket_system_url: str):
        self.siem_url = siem_url
        self.ticket_system_url = ticket_system_url
        self.client = httpx.AsyncClient()
    
    async def triage_alert(self, alert: SecurityAlert) -> dict:
        """Enrich and prioritize alert"""
        
        # Check for false positive patterns
        is_false_positive = await self._check_false_positive(alert)
        if is_false_positive:
            alert.severity = Severity.LOW
            return {"status": "dismissed", "reason": "known_false_positive"}
        
        # Correlate with threat intelligence
        threat_info = await self._lookup_threat_intel(alert.source_ip)
        
        # Check for ongoing incidents
        related_incidents = await self._find_related_incidents(alert)
        
        return {
            "status": "triaged",
            "threat_intel": threat_info,
            "related_incidents": related_incidents,
            "recommended_action": self._recommend_action(alert)
        }
    
    async def escalate_critical(self, alert: SecurityAlert):
        """Escalate critical alerts"""
        if alert.severity != Severity.CRITICAL:
            return
        
        # Create incident ticket
        ticket = await self._create_ticket(alert)
        
        # Page on-call engineer
        await self._page_oncall(alert, ticket)
        
        # Isolate affected resource (optional)
        if alert.target_resource.startswith("prod-"):
            await self._isolate_resource(alert.target_resource)
        
        # Collect forensics
        forensics_job_id = await self._start_forensics_collection(alert)
        
        return {
            "ticket_id": ticket["id"],
            "forensics_job_id": forensics_job_id
        }
    
    async def _check_false_positive(self, alert: SecurityAlert) -> bool:
        """Check against known false positive patterns"""
        # Query historical alerts for similar patterns
        response = await self.client.get(
            f"{self.siem_url}/api/alerts",
            params={
                "alert_name": alert.alert_name,
                "dismissed": "true",
                "limit": 100
            }
        )
        historical = response.json()
        
        # If >80% of similar alerts were dismissed, likely false positive
        return len(historical) > 80
    
    async def _lookup_threat_intel(self, source_ip: str) -> dict:
        """Check IP against threat intelligence feeds"""
        # Call TI service (OSINT, feeds, etc.)
        response = await self.client.get(f"https://threat-intel.example.com/ip/{source_ip}")
        return response.json()
    
    async def _find_related_incidents(self, alert: SecurityAlert) -> list:
        """Correlate with other recent alerts"""
        response = await self.client.get(
            f"{self.siem_url}/api/incidents",
            params={
                "target_resource": alert.target_resource,
                "days": 7,
                "status": "open"
            }
        )
        return response.json()
    
    def _recommend_action(self, alert: SecurityAlert) -> str:
        """Recommend incident response action"""
        if alert.severity == Severity.CRITICAL:
            return "isolate_resource"
        elif alert.alert_name == "privilege_escalation":
            return "revoke_tokens"
        elif alert.alert_name == "data_exfiltration":
            return "block_network"
        return "investigate"

# Usage
async def main():
    responder = IncidentResponder(
        siem_url="https://siem.example.com",
        ticket_system_url="https://tickets.example.com"
    )
    
    alert = SecurityAlert(
        id="ALERT-12345",
        alert_name="Privilege escalation detected",
        severity=Severity.CRITICAL,
        source_ip="203.0.113.42",
        target_resource="prod-k8s-cluster",
        timestamp="2026-05-02T02:16:00Z"
    )
    
    triage_result = await responder.triage_alert(alert)
    print(f"Triage result: {triage_result}")
    
    escalation_result = await responder.escalate_critical(alert)
    print(f"Escalation result: {escalation_result}")

asyncio.run(main())
```

---
