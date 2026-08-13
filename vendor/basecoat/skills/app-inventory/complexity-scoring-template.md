# Migration Complexity Scoring — {{APPLICATION_NAME}}

**Scan Date**: {{SCAN_DATE}}
**Scored by**: {{SCORER_NAME}}
**Review Status**: Draft / Under Review / Approved

---

## Scoring Instructions

Rate each dimension from 1 (best) to 100 (worst). Multiply by the weight to get the
weighted score. Sum all weighted scores for the overall complexity score.

Scores above 60 require solution-architect sign-off before treatment selection.

---

## Dimension 1 — Code Complexity (Weight: 20%)

Measures: cyclomatic complexity averages, lines of code density, use of anti-patterns
(God classes, magic numbers, deep inheritance), dead code percentage.

| Sub-factor | Rating (1–100) | Notes |
|-----------|--------------|-------|
| Average cyclomatic complexity | | |
| Lines of code per module | | |
| Anti-pattern count | | |
| Dead code percentage | | |
| **Dimension score (average)** | | |

**Weighted score**: (dimension score) × 0.20 = **{{CODE_WEIGHTED}}**

---

## Dimension 2 — Dependency Age (Weight: 20%)

Measures: average package age in months, percentage of dependencies more than 2 major
versions behind, count of deprecated packages, count of known CVEs.

| Sub-factor | Rating (1–100) | Notes |
|-----------|--------------|-------|
| Average package age (months behind latest) | | |
| Packages > 2 major versions behind | | |
| Deprecated packages | | |
| Known CVEs (scaled by severity) | | |
| **Dimension score (average)** | | |

**Weighted score**: (dimension score) × 0.20 = **{{DEP_WEIGHTED}}**

---

## Dimension 3 — Architecture (Weight: 20%)

Measures: monolith vs services, coupling score (afferent/efferent), layer violations,
shared database usage, synchronous call depth.

| Sub-factor | Rating (1–100) | Notes |
|-----------|--------------|-------|
| Coupling score | | |
| Layer violation count | | |
| Shared database tables (cross-service) | | |
| Synchronous call chain depth | | |
| **Dimension score (average)** | | |

**Weighted score**: (dimension score) × 0.20 = **{{ARCH_WEIGHTED}}**

---

## Dimension 4 — Test Coverage (Weight: 15%)

Measures: unit test line coverage percentage (inverted for scoring), integration test
presence, absence of contract tests for external APIs.

| Sub-factor | Rating (1–100) | Notes |
|-----------|--------------|-------|
| Unit test coverage (100 − coverage %) | | |
| Integration tests absent (0 = present, 100 = absent) | | |
| Contract tests absent (0 = present, 100 = absent) | | |
| **Dimension score (average)** | | |

**Weighted score**: (dimension score) × 0.15 = **{{TEST_WEIGHTED}}**

---

## Dimension 5 — Documentation (Weight: 10%)

Measures: README completeness (0 = full, 100 = none), inline comment density,
runbook presence, architecture decision records.

| Sub-factor | Rating (1–100) | Notes |
|-----------|--------------|-------|
| README completeness (inverted) | | |
| Inline comment coverage (inverted) | | |
| Runbook absent (0 = present, 100 = absent) | | |
| ADRs absent (0 = present, 100 = absent) | | |
| **Dimension score (average)** | | |

**Weighted score**: (dimension score) × 0.10 = **{{DOC_WEIGHTED}}**

---

## Dimension 6 — External Dependencies (Weight: 15%)

Measures: cloud-provider lock-in depth, proprietary SDK usage, vendor-managed services
without abstraction layer, external SLA dependencies.

| Sub-factor | Rating (1–100) | Notes |
|-----------|--------------|-------|
| Cloud-provider lock-in (direct API calls) | | |
| Proprietary SDK count | | |
| Unabstracted vendor integrations | | |
| External SLA dependencies | | |
| **Dimension score (average)** | | |

**Weighted score**: (dimension score) × 0.15 = **{{EXT_WEIGHTED}}**

---

## Overall Complexity Score

| Dimension | Weight | Weighted Score |
|-----------|--------|---------------|
| Code complexity | 20 % | {{CODE_WEIGHTED}} |
| Dependency age | 20 % | {{DEP_WEIGHTED}} |
| Architecture | 20 % | {{ARCH_WEIGHTED}} |
| Test coverage | 15 % | {{TEST_WEIGHTED}} |
| Documentation | 10 % | {{DOC_WEIGHTED}} |
| External dependencies | 15 % | {{EXT_WEIGHTED}} |
| **Total** | 100 % | **{{OVERALL_SCORE}}** |

## Score Interpretation

| Range | Label | Treatment signal |
|-------|-------|-----------------|
| 1–20 | Low | Rehost or quick replatform |
| 21–40 | Moderate | Planned replatform or light refactor |
| 41–60 | High | Phased refactor with strangler fig |
| 61–80 | Very high | Multi-sprint rebuild |
| 81–100 | Critical | Strategic replacement or retirement |

## Notes and Caveats

{{SCORING_NOTES}}

## Sign-off

| Role | Name | Date | Decision |
|------|------|------|----------|
| Scored by | | | |
| Solution Architect (required if score > 60) | | | Approved / Rejected |
| Product Manager (required if Retire/Replace) | | | Approved / Rejected |
