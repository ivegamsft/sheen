# Pre-Engagement Checklist

Use this checklist before starting a penetration testing engagement to ensure proper authorization, scope clarity, and legal protection.

## Authorization & Legal

- [ ] **Written Authorization Obtained**
  - [ ] Client has signed Rules of Engagement (ROE) document
  - [ ] Authorized personnel named and contacted
  - [ ] Escalation contacts identified (SOC, incident response)
  - [ ] Contact information verified and tested
  - [ ] Authorization valid for entire test window

- [ ] **Scope of Work Signed Off**
  - [ ] In-scope systems documented (CIDR ranges, domains, application URLs)
  - [ ] Out-of-scope systems explicitly listed
  - [ ] Testing windows defined (dates, times, blackout periods)
  - [ ] Executive sponsor has approved scope
  - [ ] Budget and resource constraints documented

- [ ] **Legal & Compliance Review**
  - [ ] NDA signed by all parties
  - [ ] Liability insurance verified (if required)
  - [ ] Regulatory requirements identified (HIPAA, PCI-DSS, SOX, GDPR)
  - [ ] Data handling procedures documented
  - [ ] Incident disclosure process agreed upon

## Technical Scope

- [ ] **System Inventory**
  - [ ] All in-scope IP ranges/hostnames documented
  - [ ] Services and versions identified (where known)
  - [ ] External attack surface mapped
  - [ ] API endpoints and mobile apps included
  - [ ] Third-party integrations noted (external APIs, SSO, payment processing)

- [ ] **Access Levels**
  - [ ] Unauthenticated testing scope: ___________
  - [ ] Authenticated testing (user-level credentials): ___________
  - [ ] Elevated access (admin/internal): ___________
  - [ ] Network access required (VPN/bastion): ___________
  - [ ] Test credentials provided or created: Yes / No

- [ ] **Data Classification**
  - [ ] PII handling restrictions documented
  - [ ] Payment card data (PCI) scope identified
  - [ ] Production vs. staging systems clarified
  - [ ] Data handling during exploitation approved
  - [ ] Logs retention and deletion policy agreed

## Rules of Engagement (ROE)

- [ ] **Exploit Constraints**
  - [ ] Destructive testing prohibited (no data deletion without approval)
  - [ ] Performance impact thresholds defined (e.g., no DoS-like activity)
  - [ ] Social engineering scope (phishing, pretexting, phone-based): ___________
  - [ ] Payload delivery methods approved (code injection, file upload, etc.)
  - [ ] Reverse shells/C2 communication: Permitted / Prohibited

- [ ] **Communication Protocol**
  - [ ] Critical findings escalation path defined
  - [ ] Incident response contact contacted and tested
  - [ ] Status reporting frequency agreed (daily, weekly)
  - [ ] Communication channels (email, Slack, phone): ___________
  - [ ] After-hours escalation contact provided

- [ ] **Evidence & Documentation**
  - [ ] Finding evidence retention period: ___________
  - [ ] Screenshots/video recording approved: Yes / No
  - [ ] Log access restrictions understood
  - [ ] Proof-of-concept (PoC) code ownership clarified (client keeps, tester deletes)
  - [ ] Confidentiality of non-critical findings during test

## Risk Mitigation

- [ ] **Contingency Plan**
  - [ ] Unintended impact procedure documented
  - [ ] Rollback plan for destructive tests (if any)
  - [ ] Access revocation process (credentials, VPN)
  - [ ] After-test cleanup checklist prepared
  - [ ] Client technical POC available during testing

- [ ] **Success Criteria**
  - [ ] Vulnerability threshold defined (e.g., find ≥ 1 critical finding to pass)
  - [ ] Coverage requirements documented
  - [ ] False positive handling protocol
  - [ ] Remediation priority framework established
  - [ ] Re-test and sign-off process agreed

## Team Preparation

- [ ] **Team Composition**
  - [ ] Penetration tester(s) assigned
  - [ ] Client technical lead designated
  - [ ] Incident response team notified
  - [ ] Security officer/CISO copied on communications
  - [ ] Legal team available for questions

- [ ] **Tools & Environment**
  - [ ] VPN access configured and tested
  - [ ] Proxy certificates installed (for MITM testing)
  - [ ] Scanning tools approved and whitelisted
  - [ ] Test credentials working and isolated
  - [ ] Lab environment mirrors production architecture (if applicable)

- [ ] **Knowledge Transfer**
  - [ ] Architecture overview walkthrough completed
  - [ ] Known vulnerabilities/false positives documented
  - [ ] Previous test findings reviewed
  - [ ] API documentation/Swagger access provided
  - [ ] Business logic and sensitive workflows explained

## Engagement Kickoff

- [ ] **Pre-Test Meeting Completed**
  - [ ] All stakeholders attended (client tech, security, leadership)
  - [ ] Scope and timeline reviewed with full team
  - [ ] Escalation procedures confirmed
  - [ ] Testing methodology explained (active vs. passive)
  - [ ] Reporting format and schedule set

- [ ] **Baseline Established**
  - [ ] System availability/performance baseline captured
  - [ ] Network access validated (latency, connectivity)
  - [ ] Test account credentials confirmed working
  - [ ] Logging/monitoring for test activity enabled
  - [ ] Clock synchronization between tester and systems verified

- [ ] **Sign-Off**
  - [ ] Client acknowledges authorization scope
  - [ ] All parties agree to ROE and communication plan
  - [ ] Testing can commence: ___________________ (date/time)
  - [ ] Authorized representative signature: _______________________
  - [ ] Tester acknowledgment: _______________________

---

## Notes & Adjustments

```
_____________________________________________________________________________

_____________________________________________________________________________

_____________________________________________________________________________
```

## Post-Engagement Closure (Complete After Testing)

- [ ] **Access Revoked**
  - [ ] VPN access disabled
  - [ ] Test credentials deleted/expired
  - [ ] SSH keys removed
  - [ ] Any installed agents/implants cleaned
  - [ ] Proxy certificates uninstalled

- [ ] **Data Cleanup**
  - [ ] Test data/artifacts deleted from systems
  - [ ] Local findings directory encrypted or deleted
  - [ ] PoC code/exploits removed or archived
  - [ ] Temporary files cleaned up

- [ ] **Final Reporting & Handoff**
  - [ ] Executive summary delivered
  - [ ] Detailed findings report provided
  - [ ] Remediation roadmap agreed
  - [ ] Questions answered in debrief meeting
  - [ ] Follow-up assessment timeline scheduled

---

**Engagement Number:** ___________________

**Client:** ___________________

**Test Dates:** ___________________

**Tester(s):** ___________________

**Client POC:** ___________________
