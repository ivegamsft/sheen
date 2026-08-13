# App Registration Checklist

Use this checklist when creating or reviewing an Entra ID (Azure AD) app registration. Complete every section before granting consent or issuing credentials.

## Instructions

1. Work through each section in order.
2. Mark each item ✅ (complete), ❌ (action required), or N/A.
3. Do not proceed to credential issuance until all required items are ✅ or N/A.
4. File a GitHub Issue for every ❌ item before closing this checklist.

---

## App Registration Overview

**App Name:** _[name]_
**Purpose:** _[what this app registration is for]_
**Environment:** _[dev | staging | production]_
**Owner Team:** _[team name]_
**Date:** _[YYYY-MM-DD]_
**Reviewer:** _[name or agent]_

---

## 1. Basic Configuration

| # | Item | Status | Notes |
|---|---|---|---|
| 1.1 | Display name follows naming convention (`app-<workload>-<env>`) | ☐ | |
| 1.2 | Sign-in audience is set to the minimum required (single tenant preferred) | ☐ | |
| 1.3 | Redirect URIs use HTTPS only (no HTTP in production) | ☐ | |
| 1.4 | Redirect URIs are limited to known, application-controlled domains | ☐ | |
| 1.5 | Implicit grant flows (access token, ID token) are disabled unless explicitly required | ☐ | |
| 1.6 | App is associated with the correct Entra ID tenant | ☐ | |

---

## 2. API Permissions

| # | Item | Status | Notes |
|---|---|---|---|
| 2.1 | All requested permissions are documented with business justification | ☐ | |
| 2.2 | Delegated permissions are used instead of application permissions wherever possible | ☐ | |
| 2.3 | No `*.ReadWrite.All` or `*.FullControl` permissions granted without security review | ☐ | |
| 2.4 | Microsoft Graph permissions are scoped to the minimum required | ☐ | |
| 2.5 | Admin consent has been granted for all application permissions | ☐ | |
| 2.6 | Permissions are reviewed and re-approved on a defined schedule | ☐ | |

### Permissions Inventory

| API | Permission | Type | Justification | Consented By |
|---|---|---|---|---|
| Microsoft Graph | | Delegated / Application | | |
| | | | | |

---

## 3. Credentials

| # | Item | Status | Notes |
|---|---|---|---|
| 3.1 | Client secrets have an expiry of 12 months or less | ☐ | |
| 3.2 | Secret expiry is tracked and renewal is scheduled before expiry | ☐ | |
| 3.3 | Certificates are preferred over client secrets for production workloads | ☐ | |
| 3.4 | Workload identity federation is used instead of credentials for CI/CD (GitHub Actions) | ☐ | |
| 3.5 | Credentials are stored in Key Vault — never in source code or CI/CD plain-text variables | ☐ | |
| 3.6 | No more credentials exist than are currently in active use | ☐ | |

### Credential Inventory

| # | Type | Description | Expiry | Storage Location | Rotation Owner |
|---|---|---|---|---|---|
| 1 | Secret / Certificate / Federated | | | Key Vault: _[vault name]_ | |

---

## 4. Token Configuration

| # | Item | Status | Notes |
|---|---|---|---|
| 4.1 | Access token lifetime is appropriate for the use case (default: 1 hour) | ☐ | |
| 4.2 | Optional claims are configured only when required by the application | ☐ | |
| 4.3 | Group claims are limited to assigned groups — not all groups | ☐ | |
| 4.4 | Token version is set to v2.0 for new registrations | ☐ | |

---

## 5. Ownership and Governance

| # | Item | Status | Notes |
|---|---|---|---|
| 5.1 | At least two owners are assigned — no single-owner registrations | ☐ | |
| 5.2 | Owners are current team members — no departed employees | ☐ | |
| 5.3 | Registration purpose is documented in the Notes field in Entra ID | ☐ | |
| 5.4 | App registration is included in the workload's infrastructure-as-code | ☐ | |
| 5.5 | Review cadence is defined (quarterly recommended) | ☐ | |

---

## 6. Service Principal Configuration (if applicable)

| # | Item | Status | Notes |
|---|---|---|---|
| 6.1 | Service principal exists in the target tenant | ☐ | |
| 6.2 | App role assignments are reviewed and approved | ☐ | |
| 6.3 | Service principal is assigned to a conditional access policy if it accesses sensitive resources | ☐ | |

---

## Sign-off

| Role | Name | Date | Approved |
|---|---|---|---|
| Application Owner | | | ☐ |
| Security Reviewer | | | ☐ |
| IAM Administrator | | | ☐ |

**Issues Filed:** ___ | **Blockers:** ___
