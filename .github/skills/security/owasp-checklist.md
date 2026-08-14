# OWASP Top 10 Checklist

Use this checklist to evaluate an application against the OWASP Top 10 (2021). Mark each item as **Pass**, **Fail**, or **N/A** and document evidence.

## Instructions

1. Review each category against the target codebase.
2. For each check item, record the status and supporting evidence.
3. Any **Fail** item must have a corresponding GitHub Issue filed with severity and remediation guidance.

---

## A01:2021 — Broken Access Control

| # | Check | Status | Evidence |
|---|---|---|---|
| 1.1 | All endpoints enforce authentication | ☐ Pass ☐ Fail ☐ N/A | |
| 1.2 | Authorization checks prevent IDOR (Insecure Direct Object Reference) | ☐ Pass ☐ Fail ☐ N/A | |
| 1.3 | CORS policy restricts origins to known domains | ☐ Pass ☐ Fail ☐ N/A | |
| 1.4 | Directory listing is disabled on web servers | ☐ Pass ☐ Fail ☐ N/A | |
| 1.5 | Rate limiting is applied to sensitive endpoints | ☐ Pass ☐ Fail ☐ N/A | |
| 1.6 | JWT tokens are validated for signature, expiry, and audience | ☐ Pass ☐ Fail ☐ N/A | |

## A02:2021 — Cryptographic Failures

| # | Check | Status | Evidence |
|---|---|---|---|
| 2.1 | No sensitive data transmitted in plaintext | ☐ Pass ☐ Fail ☐ N/A | |
| 2.2 | Strong encryption algorithms used (AES-256, RSA-2048+) | ☐ Pass ☐ Fail ☐ N/A | |
| 2.3 | TLS 1.2+ enforced for all external connections | ☐ Pass ☐ Fail ☐ N/A | |
| 2.4 | Passwords hashed with bcrypt, scrypt, or Argon2 | ☐ Pass ☐ Fail ☐ N/A | |
| 2.5 | Encryption keys managed via secrets manager, not hardcoded | ☐ Pass ☐ Fail ☐ N/A | |

## A03:2021 — Injection

| # | Check | Status | Evidence |
|---|---|---|---|
| 3.1 | All SQL queries use parameterized statements or ORM binding | ☐ Pass ☐ Fail ☐ N/A | |
| 3.2 | OS command execution avoids user-supplied input | ☐ Pass ☐ Fail ☐ N/A | |
| 3.3 | NoSQL queries are parameterized | ☐ Pass ☐ Fail ☐ N/A | |
| 3.4 | LDAP queries are parameterized | ☐ Pass ☐ Fail ☐ N/A | |
| 3.5 | Template engines use auto-escaping | ☐ Pass ☐ Fail ☐ N/A | |

## A04:2021 — Insecure Design

| # | Check | Status | Evidence |
|---|---|---|---|
| 4.1 | Threat model exists for the application | ☐ Pass ☐ Fail ☐ N/A | |
| 4.2 | Abuse cases are documented and tested | ☐ Pass ☐ Fail ☐ N/A | |
| 4.3 | Rate limiting protects against brute force | ☐ Pass ☐ Fail ☐ N/A | |
| 4.4 | Business logic enforces limits (e.g., transaction caps) | ☐ Pass ☐ Fail ☐ N/A | |

## A05:2021 — Security Misconfiguration

| # | Check | Status | Evidence |
|---|---|---|---|
| 5.1 | Default credentials are changed or disabled | ☐ Pass ☐ Fail ☐ N/A | |
| 5.2 | Error pages do not expose stack traces or internal details | ☐ Pass ☐ Fail ☐ N/A | |
| 5.3 | Unnecessary features, ports, and services are disabled | ☐ Pass ☐ Fail ☐ N/A | |
| 5.4 | Security headers are configured (CSP, HSTS, X-Frame-Options) | ☐ Pass ☐ Fail ☐ N/A | |
| 5.5 | Cloud storage permissions follow least privilege | ☐ Pass ☐ Fail ☐ N/A | |

## A06:2021 — Vulnerable and Outdated Components

| # | Check | Status | Evidence |
|---|---|---|---|
| 6.1 | All dependencies are on supported versions | ☐ Pass ☐ Fail ☐ N/A | |
| 6.2 | No dependencies have known Critical or High CVEs | ☐ Pass ☐ Fail ☐ N/A | |
| 6.3 | Dependency update process is automated or scheduled | ☐ Pass ☐ Fail ☐ N/A | |
| 6.4 | Unused dependencies are removed | ☐ Pass ☐ Fail ☐ N/A | |

## A07:2021 — Identification and Authentication Failures

| # | Check | Status | Evidence |
|---|---|---|---|
| 7.1 | Password policy enforces minimum complexity | ☐ Pass ☐ Fail ☐ N/A | |
| 7.2 | Multi-factor authentication is available for sensitive operations | ☐ Pass ☐ Fail ☐ N/A | |
| 7.3 | Session tokens are invalidated on logout | ☐ Pass ☐ Fail ☐ N/A | |
| 7.4 | Session tokens are rotated after privilege escalation | ☐ Pass ☐ Fail ☐ N/A | |
| 7.5 | Brute-force protection is in place (lockout or throttling) | ☐ Pass ☐ Fail ☐ N/A | |

## A08:2021 — Software and Data Integrity Failures

| # | Check | Status | Evidence |
|---|---|---|---|
| 8.1 | CI/CD pipeline integrity is protected (signed commits, branch protection) | ☐ Pass ☐ Fail ☐ N/A | |
| 8.2 | Deserialization of untrusted data is avoided or sandboxed | ☐ Pass ☐ Fail ☐ N/A | |
| 8.3 | Software updates are verified via signatures or checksums | ☐ Pass ☐ Fail ☐ N/A | |

## A09:2021 — Security Logging and Monitoring Failures

| # | Check | Status | Evidence |
|---|---|---|---|
| 9.1 | Authentication events (success and failure) are logged | ☐ Pass ☐ Fail ☐ N/A | |
| 9.2 | Authorization failures are logged with context | ☐ Pass ☐ Fail ☐ N/A | |
| 9.3 | Logs do not contain secrets, tokens, or PII | ☐ Pass ☐ Fail ☐ N/A | |
| 9.4 | Alerting is configured for anomalous patterns | ☐ Pass ☐ Fail ☐ N/A | |

## A10:2021 — Server-Side Request Forgery (SSRF)

| # | Check | Status | Evidence |
|---|---|---|---|
| 10.1 | User-supplied URLs are validated against an allowlist | ☐ Pass ☐ Fail ☐ N/A | |
| 10.2 | Internal network access is blocked for user-initiated requests | ☐ Pass ☐ Fail ☐ N/A | |
| 10.3 | DNS rebinding protections are in place | ☐ Pass ☐ Fail ☐ N/A | |

---

## Summary

| Category | Status | Issues Filed |
|---|---|---|
| A01 — Broken Access Control | | |
| A02 — Cryptographic Failures | | |
| A03 — Injection | | |
| A04 — Insecure Design | | |
| A05 — Security Misconfiguration | | |
| A06 — Vulnerable Components | | |
| A07 — Auth Failures | | |
| A08 — Data Integrity Failures | | |
| A09 — Logging & Monitoring Failures | | |
| A10 — SSRF | | |

**Total Findings:** ___ | **Issues Filed:** ___
