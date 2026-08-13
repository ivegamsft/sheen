# .NET Breaking-Change Tracking Guide

This reference helps teams capture and manage known breaking changes while modernizing to newer .NET targets.

## Recommended workflow

1. Build an inventory of framework and package versions currently in use.
2. Map each upgrade jump (for example, .NET Framework 4.8 -> .NET 8) to official breaking-change notes.
3. Log each confirmed impact with owner, mitigation, and validation test.
4. Gate each migration wave on closure of critical and high-severity impacts.

## Suggested tracking fields

| Field | Purpose |
|---|---|
| Component | Assembly/package/service affected |
| Current Version | Baseline version in production |
| Target Version | Planned upgraded version |
| Change Type | API removal, behavior change, config/runtime change |
| Severity | Low/Medium/High/Critical |
| Mitigation | Code/config/test change needed |
| Owner | Responsible engineer/team |
| Validation | Test or check that proves mitigation |
| Status | Open/In Progress/Validated |

## Validation checklist

- Build passes for each migrated project
- Contract/integration tests pass against upgraded dependencies
- Performance regressions are within accepted thresholds
- Operational telemetry and alerts remain healthy post-upgrade
