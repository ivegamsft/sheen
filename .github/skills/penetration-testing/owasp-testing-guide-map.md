# OWASP Testing Guide v4.2 — Test Case Map & Coverage Tracker

Reference: [OWASP Web Security Testing Guide v4.2](https://owasp.org/www-project-web-security-testing-guide/)

## I. Information Gathering (WSTG-INFO)

### WSTG-INFO-001: Conduct Web Application Fingerprinting

| Test | Objective | Method | Status |
|------|-----------|--------|--------|
| Technology Stack Detection | Identify web server, frameworks, languages | HTTP headers, HTML comments, error pages, responses.json | ☐ |
| CMS Detection | Identify WordPress, Drupal, Joomla, custom CMS | Plugin/theme fingerprints, default paths | ☐ |
| Web Application Firewall (WAF) Detection | Identify WAF presence and type | Bypass attempts, error pattern analysis | ☐ |

### WSTG-INFO-002: Application Discovery

| Test | Objective | Method | Status |
|------|-----------|--------|--------|
| Subdomain Enumeration | Find hidden subdomains | subfinder, Shodan, DNS brute force | ☐ |
| API Endpoint Discovery | Map API surface | Swagger/OpenAPI, burp crawl, nuclei templates | ☐ |
| Hidden Directories | Find admin/backup/debug paths | dirb, gobuster, common path lists | ☐ |
| File Upload Locations | Identify upload endpoints | Crawl, grep for upload forms, API testing | ☐ |

### WSTG-INFO-003: Review Webserver Metafiles

| Test | Objective | Method | Status |
|------|-----------|--------|--------|
| robots.txt Analysis | Extract disallowed paths (often sensitive) | curl https://target.com/robots.txt | ☐ |
| sitemap.xml Analysis | Map authenticated areas | curl https://target.com/sitemap.xml | ☐ |
| .well-known/ Review | ACME challenges, security.txt, jwks | ls -la https://target.com/.well-known/ | ☐ |

---

## II. Configuration & Deployment Management (WSTG-CONF)

### WSTG-CONF-001: Test Network Infrastructure Configuration

| Test | Objective | Method | Status |
|------|-----------|--------|--------|
| Network Segmentation | Verify dev/staging/prod isolation | traceroute, nmap -sS, port scanning | ☐ |
| DNS Configuration | Check for DNS spoofing, zone transfer | nslookup -type=AXFR, dig axfr | ☐ |
| Mail Server Config | Check SMTP relay, SPF/DKIM/DMARC | nmap -sV, mailbox-validator | ☐ |

### WSTG-CONF-002: Test Application Platform Configuration

| Test | Objective | Method | Status |
|------|-----------|--------|--------|
| Default Credentials | Test common admin passwords | hydra, medusa, credential stuffing | ☐ |
| Debug Interfaces | Find debug endpoints exposing data | /.git, /.env, /debug, /metrics, /__debug | ☐ |
| Verbose Error Messages | Check for stack traces, config paths in errors | Trigger errors, observe responses | ☐ |
| Security Headers | Check HSTS, CSP, X-Frame-Options, etc. | curl -I, burp headers tab | ☐ |

### WSTG-CONF-003: Test File Extensions Handling

| Test | Objective | Method | Status |
|------|-----------|--------|--------|
| Unusual Extension Execution | Test .php.txt, .php%00.jpg | Upload/request malicious extensions | ☐ |
| Directory Traversal via Extension | ../ escaping in filenames | Upload ../../../etc/passwd.php | ☐ |
| Null Byte Bypass | .php%00.jpg, .php\x00.jpg | Older PHP versions vulnerable | ☐ |

### WSTG-CONF-004: Review Old Backup and Unreferenced Files

| Test | Objective | Method | Status |
|------|-----------|--------|--------|
| Backup File Discovery | Find .bak, .old, .zip, .tar.gz, .sql | dirb, grep for common backup patterns | ☐ |
| Source Code Exposure | .java~, .py.bak, web.config.bak | Upload forms, directory listing | ☐ |
| Database Dumps | .sql, .dump, schema exports | Directory traversal, backup paths | ☐ |

---

## III. Authentication Testing (WSTG-ATHN)

### WSTG-ATHN-001: Testing for Weak Password Policy

| Test | Objective | Method | Status |
|------|-----------|--------|--------|
| Minimum Length | 6 chars or less allowed | Register with "pass" | ☐ |
| Character Mix | Alphabetic-only passwords accepted | Register with "abcdef" | ☐ |
| Numeric-Only Acceptance | Numbers only acceptable | Register with "123456" | ☐ |
| Password History | No check for reused passwords | Change to same password | ☐ |

### WSTG-ATHN-002: Testing for Weak Lock Out Mechanism

| Test | Objective | Method | Status |
|------|-----------|--------|--------|
| Brute Force Protection | No rate limiting after N attempts | 100+ login attempts | ☐ |
| Account Lockout Time | Indefinite or too long | Try to unlock after 5 min | ☐ |
| Lockout Bypass | Username enumeration despite lockout | Use timing/response analysis | ☐ |

### WSTG-ATHN-003: Testing for Weak Session Cookie Configuration

| Test | Objective | Method | Status |
|------|-----------|--------|--------|
| HttpOnly Flag | Cookies accessible via JavaScript | Check response headers | ☐ |
| Secure Flag | Cookie sent over HTTP | Check response headers | ☐ |
| SameSite Attribute | CSRF protection not enforced | Cross-site request attempt | ☐ |
| Session ID Prediction | Sequential or weak generation | Capture multiple IDs, analyze entropy | ☐ |

### WSTG-ATHN-004: Testing for Session Fixation

| Test | Objective | Method | Status |
|------|-----------|--------|--------|
| Pre-Login Session ID Reuse | Session ID same before/after login | Capture before login, use after login | ☐ |
| URL-Based Session IDs | Session in URL (not cookie) | Check if URL rewritable | ☐ |

### WSTG-ATHN-005: Testing for Authentication Bypass

| Test | Objective | Method | Status |
|------|-----------|--------|--------|
| SQL Injection in Login | admin' -- or admin' or '1'='1 | Inject SQL payloads | ☐ |
| NoSQL Injection in Login | {"username": {"$ne": ""}} | Test JSON/NoSQL backends | ☐ |
| LDAP Injection | admin*)(objectClass=* | Test LDAP backends | ☐ |
| Default Credentials | admin/admin, root/root | Try common defaults | ☐ |
| Authentication Logic Bypass | Modification of hidden tokens | Intercept, modify, replay | ☐ |

### WSTG-ATHN-006: Testing for Vulnerable Remember-Me Functionality

| Test | Objective | Method | Status |
|------|-----------|--------|--------|
| Remember-Me Token Prediction | Token is username/timestamp base64 | Decode, predict next token | ☐ |
| Token Rotation on Login | Same token across sessions | Login 2x, compare tokens | ☐ |
| Token Invalidation | Old token works after logout | Test expired/revoked tokens | ☐ |

---

## IV. Authorization Testing (WSTG-AUTHZ)

### WSTG-AUTHZ-001: Testing for Broken Object-Level Authorization (BOLA)

| Test | Objective | Method | Status |
|------|-----------|--------|--------|
| Resource Enumeration | User A accesses User B's data | Enumerate IDs, test access | ☐ |
| Cross-Tenant Access | User from Org A accesses Org B data | Test tenant-id parameter | ☐ |
| Parameter Tampering | Modify user_id in request | Change ID to another user's | ☐ |

### WSTG-AUTHZ-002: Testing for Privilege Escalation

| Test | Objective | Method | Status |
|------|-----------|--------|--------|
| Horizontal Escalation | User becomes another user same role | Modify user_id parameter | ☐ |
| Vertical Escalation | User becomes admin | Modify role/is_admin field | ☐ |
| Admin Panel Access | Direct URL to /admin bypasses auth | Test /admin, /administrator | ☐ |

### WSTG-AUTHZ-003: Testing for Insecure Direct Object References (IDOR)

| Test | Objective | Method | Status |
|------|-----------|--------|--------|
| Predictable IDs | Enumerate /invoices/1, /invoices/2 | Try sequential/UUID IDs | ☐ |
| UUID Guessing | UUID format predictable or weak | Generate, try variants | ☐ |

### WSTG-AUTHZ-004: Testing for Insecure Direct Object References (IDOR)

| Test | Objective | Method | Status |
|------|-----------|--------|--------|
| Session-Based RBAC Bypass | Modify JWT role claim | Tamper with JWT payload | ☐ |
| Client-Side Authorization Check | Role check only on frontend | Inspect network requests | ☐ |

---

## V. Session Management Testing (WSTG-SESS)

### WSTG-SESS-001: Testing for Session Management Schema

| Test | Objective | Method | Status |
|------|-----------|--------|--------|
| Session Token Format | Cookie vs. header vs. URL | Review token handling | ☐ |
| Token Entropy | Predictable pattern analysis | Capture multiple tokens, analyze | ☐ |
| Token Regeneration | After login, logout, privilege change | Capture and compare tokens | ☐ |

---

## VI. Input Validation Testing (WSTG-INPV)

### WSTG-INPV-001: Testing for Reflected Cross-Site Scripting (XSS)

| Test | Objective | Method | Status |
|------|-----------|--------|--------|
| Query Parameter Injection | /search?q=<script>alert(1)</script> | Check response for unescaped input | ☐ |
| Path Parameter Injection | /user/<script>alert(1)</script>/profile | Test path-based reflection | ☐ |
| HTTP Header Injection | Referer: <script>alert(1)</script> | Test header reflection | ☐ |

### WSTG-INPV-002: Testing for Stored Cross-Site Scripting (XSS)

| Test | Objective | Method | Status |
|------|-----------|--------|--------|
| Comment/Review Injection | Post <img onerror=alert(1)> | Verify stored and executed | ☐ |
| Profile/Bio Injection | Update bio with XSS payload | Check if executed on page view | ☐ |
| Email/Message Storage | Send <script> in message | Check if executed when viewed | ☐ |

### WSTG-INPV-003: Testing for HTTP Response Splitting (CRLFi)

| Test | Objective | Method | Status |
|------|-----------|--------|--------|
| Header Injection | /page?url=google.com%0d%0aSet-Cookie: session=hacked | Inject CRLF in params | ☐ |
| Cache Poisoning | Inject via reflected param in Cache-Control | CRLF to create cached response | ☐ |

### WSTG-INPV-004: Testing for SQL Injection (SQLi)

| Test | Objective | Method | Status |
|------|-----------|--------|--------|
| Error-Based SQLi | admin' OR '1'='1 | Inject quotes, observe errors | ☐ |
| Boolean-Based Blind SQLi | AND 1=1 (true) vs AND 1=2 (false) | Observe response differences | ☐ |
| Time-Based Blind SQLi | ' OR SLEEP(5)-- | Measure response time | ☐ |
| Union-Based SQLi | ' UNION SELECT 1,2,3-- | Extract via UNION queries | ☐ |

### WSTG-INPV-005: Testing for LDAP Injection

| Test | Objective | Method | Status |
|------|-----------|--------|--------|
| Filter Manipulation | admin*)(&mail=* | Inject LDAP filter metacharacters | ☐ |

### WSTG-INPV-006: Testing for XML Injection (XXE)

| Test | Objective | Method | Status |
|------|-----------|--------|--------|
| External Entity Loading | <!DOCTYPE foo [<!ENTITY xxe SYSTEM "file:///etc/passwd">]> | Upload XML with XXE | ☐ |
| XXE via SOAP | SOAP request with XXE payload | Inject XXE in SOAP envelope | ☐ |

### WSTG-INPV-007: Testing for Command Injection

| Test | Objective | Method | Status |
|------|-----------|--------|--------|
| OS Command Separator | google.com; whoami | Inject ; , && , || | ☐ |
| Newline Injection | google.com%0awhoami | Inject newlines (NUL bytes) | ☐ |
| Backtick Execution | `whoami` inside parameter | Use backticks for command execution | ☐ |

### WSTG-INPV-008: Testing for Path Traversal

| Test | Objective | Method | Status |
|------|-----------|--------|--------|
| Directory Traversal | /download?file=../../../../etc/passwd | Inject ../ sequences | ☐ |
| Null Byte Bypass | /file.pdf%00.jpg | Null byte to bypass extensions | ☐ |
| Double Encoding | ....//....// | Bypass single-pass filter | ☐ |

---

## VII. Testing for Weak Cryptography (WSTG-CRYP)

### WSTG-CRYP-001: Testing for Weak SSL/TLS Configuration

| Test | Objective | Method | Status |
|------|-----------|--------|--------|
| SSL Version | SSLv2, SSLv3, TLS 1.0, 1.1 | testssl.sh, sslscan | ☐ |
| Weak Ciphers | RC4, DES, NULL ciphers | nmap --script ssl-enum-ciphers | ☐ |
| Certificate Validation | Self-signed, expired, mismatched CN | Check HTTPS warnings | ☐ |

### WSTG-CRYP-002: Testing for Sensitive Data Exposure

| Test | Objective | Method | Status |
|------|-----------|--------|--------|
| Hardcoded Secrets | API keys, passwords in source | grep -r "password\|api_key" | ☐ |
| Exposed in Git History | Secrets in .git repo | git log --all -S password | ☐ |
| Unencrypted Storage | Plain-text credentials in database | Database query inspection | ☐ |

---

## VIII. Error Handling & Logging (WSTG-ERR)

### WSTG-ERR-001: Analysis of Error Codes

| Test | Objective | Method | Status |
|------|-----------|--------|--------|
| Information Disclosure | Stack traces, SQL errors, paths | Trigger 404, 500, SQL errors | ☐ |
| Error Message Enumeration | Username exists vs. invalid password | Compare login error messages | ☐ |

### WSTG-ERR-002: Analysis of Stack Traces

| Test | Objective | Method | Status |
|------|-----------|--------|--------|
| Stack Trace Exposure | Full traceback visible in error pages | Trigger exceptions | ☐ |
| Source Code in Error Messages | File paths, code snippets | Analyze error output | ☐ |

---

## IX. Weak Cryptographic Storage (WSTG-CRYP)

### WSTG-CRYP-003: Testing for Weak Encryption

| Test | Objective | Method | Status |
|------|-----------|--------|--------|
| MD5/SHA1 for Passwords | Weak hashing algorithms | Database inspection | ☐ |
| No Salting | All users same hash for same password | Hash comparison | ☐ |
| Weak IV/Key Derivation | Predictable or short keys | Cryptanalysis | ☐ |

---

## X. Business Logic (WSTG-BUSL)

### WSTG-BUSL-001: Test Business Logic Data Validation

| Test | Objective | Method | Status |
|------|-----------|--------|--------|
| Numeric Field Bypass | Negative price, 0 quantity | Modify numeric inputs | ☐ |
| State Machine Bypass | Skip order approval steps | Modify workflow via parameter tampering | ☐ |
| Race Condition | Two simultaneous purchases, insufficient funds | Parallel requests | ☐ |

### WSTG-BUSL-002: Test Ability to Forge Requests

| Test | Objective | Method | Status |
|------|-----------|--------|--------|
| Workflow Bypass | Delete approval step from sequence | Modify request flow | ☐ |
| Transaction Reversal | Refund after shipment | Trigger refund logic | ☐ |

---

## XI. Client-side Testing (WSTG-CLNT)

### WSTG-CLNT-001: Testing for DOM-Based XSS

| Test | Objective | Method | Status |
|------|-----------|--------|--------|
| JavaScript Input Sink | location.href = userInput | Test DOM manipulation | ☐ |
| innerHTML Usage | document.getElementById().innerHTML | Check JavaScript source | ☐ |

### WSTG-CLNT-002: Testing for Client-Side URL Redirect

| Test | Objective | Method | Status |
|------|-----------|--------|--------|
| Open Redirect | /redirect?url=https://attacker.com | Test URL parameter | ☐ |
| Whitelist Bypass | //attacker.com, javascript: URI | Bypass domain check | ☐ |

---

## API-Specific Testing (OWASP API Top 10)

### API-001: Broken Object Level Authorization

**Status:** ☐

### API-002: Broken Authentication

**Status:** ☐

### API-003: Excessive Data Exposure

**Status:** ☐

### API-004: Lack of Resources & Rate Limiting

**Status:** ☐

### API-005: Broken Function Level Authorization

**Status:** ☐

### API-006: Mass Assignment

**Status:** ☐

### API-007: Security Misconfiguration

**Status:** ☐

### API-008: Injection

**Status:** ☐

### API-009: Improper Assets Management

**Status:** ☐

### API-010: Insufficient Logging & Monitoring

**Status:** ☐

---

## Summary

- **Total Test Cases:** ___________
- **Completed:** ___________
- **Pass Rate:** ___________
- **Critical Findings:** ___________
- **High Findings:** ___________
- **Engagement Completion Date:** ___________
