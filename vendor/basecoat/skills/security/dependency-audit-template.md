# Dependency Audit Template

Use this template to document the results of a dependency vulnerability assessment.

## Audit Metadata

| Field | Value |
|---|---|
| **Application** | _[name]_ |
| **Audit Date** | _[YYYY-MM-DD]_ |
| **Analyst** | _[name or agent]_ |
| **Package Manager(s)** | _[npm / pip / go mod / NuGet / Maven / etc.]_ |
| **Manifest File(s)** | _[package.json, requirements.txt, go.mod, etc.]_ |

---

## Summary

| Metric | Value |
|---|---|
| Total dependencies (direct) | |
| Total dependencies (transitive) | |
| Dependencies with known CVEs | |
| Critical severity | |
| High severity | |
| Medium severity | |
| Low severity | |

---

## Vulnerable Dependencies

### Dependency #1

| Field | Value |
|---|---|
| **Package** | _[name]_ |
| **Current Version** | _[version]_ |
| **Type** | _Direct / Transitive_ |
| **CVE(s)** | _[CVE-YYYY-NNNNN]_ |
| **Severity** | _Critical / High / Medium / Low_ |
| **CVSS Score** | _[score]_ |
| **Description** | _[brief description of the vulnerability]_ |
| **Fix Version** | _[patched version, if available]_ |
| **GitHub Issue** | _[#number]_ |

**Remediation:**
_Upgrade to version X.Y.Z / Replace with alternative package / Pin transitive dependency._

**Risk if Unpatched:**
_Describe the exploitability and impact in the context of this application._

---

_Repeat the "Dependency" section for each vulnerable dependency._

---

## Deprecated or Unmaintained Dependencies

| Package | Version | Last Published | Reason | Recommended Action |
|---|---|---|---|---|
| | | | No updates in 2+ years | Replace with _[alternative]_ |

---

## License Compliance

| Package | Version | License | Compatible | Notes |
|---|---|---|---|---|
| | | | ☐ Yes ☐ No | |

---

## Recommendations

1. _Upgrade all dependencies with Critical and High CVEs immediately._
2. _Enable automated dependency scanning in CI/CD pipeline._
3. _Schedule regular dependency review cadence (monthly recommended)._
4. _Remove unused dependencies to reduce attack surface._
5. _Pin dependency versions and use lock files to prevent supply-chain attacks._

## Next Audit

**Scheduled Date:** _[YYYY-MM-DD]_
