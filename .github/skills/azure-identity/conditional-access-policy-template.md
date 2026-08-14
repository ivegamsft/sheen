# Conditional Access Policy Template

Use this template to design Conditional Access (CA) policies that enforce zero trust principles across users, devices, applications, and network locations.

## Instructions

1. Define each policy with a clear, unique name following the naming convention.
2. Assign every policy to a named group — avoid applying policies to "All users" without a break-glass exclusion.
3. Always exclude break-glass accounts from every policy.
4. Set policies to **Report-only** mode before enabling them in production.
5. Review sign-in logs after 7 days in Report-only mode before switching to **Enabled**.
6. Document the zero trust principle each policy enforces.

---

## Policy Overview

**Workload / Scope:** _[name]_
**Environment:** _[dev | staging | production]_
**Tenant:** _[tenant name or ID]_
**Date:** _[YYYY-MM-DD]_
**Author:** _[name or agent]_

---

## Break-Glass Account Configuration

Before creating any policies, verify break-glass accounts are excluded.

| Item | Status | Notes |
|---|---|---|
| Break-glass accounts exist (minimum 2) | ☐ | |
| Break-glass accounts use long, randomised passwords (24+ chars) | ☐ | |
| Break-glass accounts do not have standard MFA registered (authenticator app or SMS) — access uses a FIDO2 hardware security key stored physically offline | ☐ | |
| Break-glass accounts are excluded from all CA policies | ☐ | |
| Break-glass account usage triggers an alert | ☐ | |

---

## Policy Definitions

---

### Policy: CA-001 — Require MFA for All Users

**Purpose:** Enforce multi-factor authentication for every interactive sign-in.
**Zero Trust Principle:** Verify explicitly — always authenticate with more than one factor.

| Field | Value |
|---|---|
| **Name** | `CA-001 — Require MFA for all users` |
| **State** | Report-only → Enabled |
| **Assignments — Users** | All users |
| **Assignments — Exclude** | Break-glass group, Service accounts group |
| **Assignments — Cloud apps** | All cloud apps |
| **Conditions — Sign-in risk** | Not configured |
| **Conditions — Device platforms** | Not configured |
| **Conditions — Locations** | Not configured |
| **Grant — Access control** | Require multifactor authentication |
| **Session controls** | Not configured |

---

### Policy: CA-002 — Block Legacy Authentication

**Purpose:** Block all authentication requests using legacy protocols that do not support MFA.
**Zero Trust Principle:** Assume breach — eliminate insecure access vectors.

| Field | Value |
|---|---|
| **Name** | `CA-002 — Block legacy authentication` |
| **State** | Enabled |
| **Assignments — Users** | All users |
| **Assignments — Exclude** | Break-glass group |
| **Assignments — Cloud apps** | All cloud apps |
| **Conditions — Client apps** | Exchange ActiveSync clients, Other clients (legacy auth) |
| **Grant — Access control** | Block access |

---

### Policy: CA-003 — Require Compliant Device for Sensitive Apps

**Purpose:** Require Intune-compliant or Hybrid Azure AD joined devices to access sensitive applications.
**Zero Trust Principle:** Use least-privileged access — device health must be verified before granting access.

| Field | Value |
|---|---|
| **Name** | `CA-003 — Require compliant device for sensitive apps` |
| **State** | Report-only → Enabled |
| **Assignments — Users** | All users |
| **Assignments — Exclude** | Break-glass group |
| **Assignments — Cloud apps** | _[list sensitive app registrations]_ |
| **Conditions — Device platforms** | Windows, macOS, iOS, Android |
| **Grant — Access control** | Require device to be marked as compliant OR Require Hybrid Azure AD join |

---

### Policy: CA-004 — High Sign-In Risk Requires MFA Re-Authentication

**Purpose:** Force MFA step-up when Entra ID detects a high-risk sign-in.
**Zero Trust Principle:** Verify explicitly — re-authenticate when risk is elevated.

| Field | Value |
|---|---|
| **Name** | `CA-004 — High sign-in risk requires MFA` |
| **State** | Report-only → Enabled |
| **Assignments — Users** | All users |
| **Assignments — Exclude** | Break-glass group |
| **Assignments — Cloud apps** | All cloud apps |
| **Conditions — Sign-in risk** | High |
| **Grant — Access control** | Require multifactor authentication |
| **Session controls** | Sign-in frequency: Every time |

---

### Policy: CA-005 — Require MFA for Azure Management

**Purpose:** Enforce MFA for all access to the Azure portal, Azure CLI, and Azure Resource Manager.
**Zero Trust Principle:** Verify explicitly — privileged resource management always requires a second factor.

| Field | Value |
|---|---|
| **Name** | `CA-005 — Require MFA for Azure management` |
| **State** | Enabled |
| **Assignments — Users** | All users |
| **Assignments — Exclude** | Break-glass group |
| **Assignments — Cloud apps** | Microsoft Azure Management (797f4846-ba00-4fd7-ba43-dac1f8f63013) |
| **Grant — Access control** | Require multifactor authentication |

---

### Policy: CA-006 — Workload Identity — Block Risky Service Principals (Optional)

**Purpose:** Block service principals flagged as high-risk by Entra ID Protection.
**Zero Trust Principle:** Assume breach — revoke service principal access when risk is detected.

| Field | Value |
|---|---|
| **Name** | `CA-006 — Block risky workload identities` |
| **State** | Report-only → Enabled |
| **Assignments — Workload identities** | All service principals |
| **Conditions — Service principal risk** | High |
| **Grant — Access control** | Block access |

---

## Custom Policy Template

Use this template to define additional policies.

| Field | Value |
|---|---|
| **Name** | `CA-NNN — [descriptive name]` |
| **State** | Report-only |
| **Zero Trust Principle** | |
| **Assignments — Users** | |
| **Assignments — Exclude** | Break-glass group |
| **Assignments — Cloud apps** | |
| **Conditions** | |
| **Grant — Access control** | |
| **Session controls** | |
| **Business Justification** | |
| **Review Date** | |

---

## Policy Deployment Checklist

| # | Step | Status |
|---|---|---|
| 1 | Break-glass accounts verified and excluded from all policies | ☐ |
| 2 | All policies set to Report-only before production enablement | ☐ |
| 3 | Sign-in logs reviewed after 7 days in Report-only mode | ☐ |
| 4 | Helpdesk notified before enabling MFA policies | ☐ |
| 5 | Named locations configured for trusted networks | ☐ |
| 6 | Alert configured for break-glass account usage | ☐ |
| 7 | All policies documented in this template and stored in version control | ☐ |
| 8 | Policy review cadence defined (quarterly recommended) | ☐ |

---

**Policies Defined:** ___ | **Enabled:** ___ | **Report-only:** ___ | **Break-glass Excluded:** ___
