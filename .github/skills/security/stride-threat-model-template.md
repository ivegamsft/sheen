# STRIDE Threat Model Template

Use this template to enumerate and rate threats for each component and trust boundary in the system.

## Instructions

1. Identify all components and trust boundaries in the system.
2. For each component, evaluate all six STRIDE categories.
3. Rate each threat by likelihood (Low/Medium/High) and impact (Low/Medium/High).
4. Document recommended mitigations and link to filed issues.

---

## System Overview

**Application:** _[name]_
**Version/Commit:** _[version or SHA]_
**Date:** _[YYYY-MM-DD]_
**Analyst:** _[name or agent]_

### Architecture Summary

_Provide a brief description of the system architecture, key components, data flows, and external integrations._

### Trust Boundaries

| # | Boundary | Description |
|---|---|---|
| TB-1 | | |
| TB-2 | | |
| TB-3 | | |

### Components

| # | Component | Type | Trust Boundary |
|---|---|---|---|
| C-1 | | | |
| C-2 | | | |
| C-3 | | | |

---

## Threat Enumeration

### Component: _[C-1 name]_

#### Spoofing

| Threat ID | Description | Likelihood | Impact | Mitigation | Issue |
|---|---|---|---|---|---|
| S-1 | | ☐ Low ☐ Med ☐ High | ☐ Low ☐ Med ☐ High | | |

#### Tampering

| Threat ID | Description | Likelihood | Impact | Mitigation | Issue |
|---|---|---|---|---|---|
| T-1 | | ☐ Low ☐ Med ☐ High | ☐ Low ☐ Med ☐ High | | |

#### Repudiation

| Threat ID | Description | Likelihood | Impact | Mitigation | Issue |
|---|---|---|---|---|---|
| R-1 | | ☐ Low ☐ Med ☐ High | ☐ Low ☐ Med ☐ High | | |

#### Information Disclosure

| Threat ID | Description | Likelihood | Impact | Mitigation | Issue |
|---|---|---|---|---|---|
| I-1 | | ☐ Low ☐ Med ☐ High | ☐ Low ☐ Med ☐ High | | |

#### Denial of Service

| Threat ID | Description | Likelihood | Impact | Mitigation | Issue |
|---|---|---|---|---|---|
| D-1 | | ☐ Low ☐ Med ☐ High | ☐ Low ☐ Med ☐ High | | |

#### Elevation of Privilege

| Threat ID | Description | Likelihood | Impact | Mitigation | Issue |
|---|---|---|---|---|---|
| E-1 | | ☐ Low ☐ Med ☐ High | ☐ Low ☐ Med ☐ High | | |

---

_Repeat the "Component" section for each component identified above._

---

## Risk Summary

| Severity | Count | Top Threats |
|---|---|---|
| Critical (High likelihood + High impact) | | |
| High (High likelihood + Med impact, or Med likelihood + High impact) | | |
| Medium (Med likelihood + Med impact) | | |
| Low (Low likelihood and/or Low impact) | | |

## Mitigations Summary

| Priority | Threat ID | Mitigation | Owner | Status |
|---|---|---|---|---|
| 1 | | | | ☐ Open |
| 2 | | | | ☐ Open |
| 3 | | | | ☐ Open |

**Total Threats Identified:** ___ | **Issues Filed:** ___
