# App Inventory Report: {{APPLICATION_NAME}}

## Overview

- **Scan Date**: {{SCAN_TIMESTAMP}}
- **Application**: {{APPLICATION_NAME}}
- **Repository**: {{REPOSITORY_PATH}}
- **Last Modified**: {{LAST_MODIFIED}}
- **Scanner Version**: {{AGENT_VERSION}}

## Technology Stack

- **Primary Language**: {{PRIMARY_LANGUAGE}}
- **Framework**: {{FRAMEWORK}} {{FRAMEWORK_VERSION}}
- **Framework EOL**: {{FRAMEWORK_EOL_DATE}} — {{EOL_STATUS}}
- **Database**: {{DATABASE}}
- **Containers**: {{CONTAINER_PLATFORM}}
- **Deployment Target**: {{DEPLOYMENT_TARGET}}
- **Build Tool**: {{BUILD_TOOL}}

## Dependency Summary

| Metric | Count |
|--------|-------|
| Package managers discovered | {{PACKAGE_MANAGER_COUNT}} |
| Direct dependencies | {{DIRECT_COUNT}} |
| Transitive dependencies | {{TRANSITIVE_COUNT}} |
| Outdated packages | {{OUTDATED_COUNT}} |
| Deprecated packages | {{DEPRECATED_COUNT}} |
| Security vulnerabilities (CRITICAL) | {{VULN_CRITICAL}} |
| Security vulnerabilities (HIGH) | {{VULN_HIGH}} |
| Security vulnerabilities (MEDIUM) | {{VULN_MEDIUM}} |
| License risk flags | {{LICENSE_RISK_COUNT}} |

### Critical and High Vulnerabilities

| Package | Version | Severity | CVE | Remediation |
|---------|---------|----------|-----|-------------|
| {{PACKAGE_NAME}} | {{PACKAGE_VERSION}} | {{SEVERITY}} | {{CVE_ID}} | {{REMEDIATION}} |

### Outdated Key Packages

| Package | Current | Latest | Gap (months) | EOL? |
|---------|---------|--------|-------------|------|
| {{PACKAGE}} | {{CURRENT_VERSION}} | {{LATEST_VERSION}} | {{GAP}} | {{EOL}} |

## Architecture

- **Style**: {{ARCHITECTURE_STYLE}} (Monolithic / Modular Monolith / Microservices / Mini-services)
- **Layers**: {{LAYER_LIST}}
- **ORM / Data Access**: {{ORM_NAME}}
- **Authentication**: {{AUTH_MECHANISM}}

### Database Connections

| Name | Provider | Server/Host | Notes |
|------|---------|-------------|-------|
| {{CONN_NAME}} | {{PROVIDER}} | {{HOST}} | {{NOTES}} |

### External Service Dependencies

| Service | Protocol | Direction | Notes |
|---------|---------|-----------|-------|
| {{SERVICE}} | {{PROTOCOL}} | Inbound / Outbound | {{NOTES}} |

### Message Queue Bindings

| Queue / Topic | Provider | Direction | Notes |
|--------------|---------|-----------|-------|
| {{QUEUE}} | {{PROVIDER}} | Producer / Consumer | {{NOTES}} |

## Migration Complexity Score: {{OVERALL_SCORE}}/100

| Dimension | Score (/100) | Weight | Weighted Score | Key Finding |
|-----------|-------------|--------|---------------|-------------|
| Code complexity | {{CODE_SCORE}} | 20 % | {{CODE_WEIGHTED}} | {{CODE_FINDING}} |
| Dependency age | {{DEP_SCORE}} | 20 % | {{DEP_WEIGHTED}} | {{DEP_FINDING}} |
| Architecture | {{ARCH_SCORE}} | 20 % | {{ARCH_WEIGHTED}} | {{ARCH_FINDING}} |
| Test coverage | {{TEST_SCORE}} | 15 % | {{TEST_WEIGHTED}} | {{TEST_FINDING}} |
| Documentation | {{DOC_SCORE}} | 10 % | {{DOC_WEIGHTED}} | {{DOC_FINDING}} |
| External dependencies | {{EXT_SCORE}} | 15 % | {{EXT_WEIGHTED}} | {{EXT_FINDING}} |
| **Overall** | | | **{{OVERALL_SCORE}}** | |

## Portfolio Category

**{{PORTFOLIO_CATEGORY}}** — {{PORTFOLIO_RATIONALE}}

Categories: Keep & Invest / Keep & Maintain / Modernize / Consolidate / Retire

## Recommended Treatment Path

**{{TREATMENT_PATH}}** (see `docs/treatment-matrix.md`)

## Key Recommendations

1. {{RECOMMENDATION_1}}
2. {{RECOMMENDATION_2}}
3. {{RECOMMENDATION_3}}
4. {{RECOMMENDATION_4}}

## Next Steps

| Action | Owner | Target Sprint | Notes |
|--------|-------|--------------|-------|
| {{ACTION_1}} | {{OWNER_1}} | {{SPRINT_1}} | {{NOTES_1}} |
| {{ACTION_2}} | {{OWNER_2}} | {{SPRINT_2}} | {{NOTES_2}} |

## Appendix — Raw Scan Output

Attach or link the raw JSON/YAML scan output from the `app-inventory` agent here for
traceability.

- **JSON report**: `{{JSON_REPORT_PATH}}`
- **YAML report**: `{{YAML_REPORT_PATH}}`
