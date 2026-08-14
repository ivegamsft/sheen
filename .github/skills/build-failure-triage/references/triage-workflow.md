# Build Failure Triage Workflow

## 1. Capture

- Capture failing workflow, job, and step.
- Save first failing error block (not downstream noise).

## 2. Classify

- **Dependency**: package resolution, lockfile mismatch
- **Toolchain**: compiler/runtime version mismatch
- **Test**: deterministic failure vs flake
- **Environment**: secrets, network, permissions, quota
- **Config**: workflow or script drift

## 3. Remediate (smallest safe fix first)

1. Fix first failing step only.
2. Re-run targeted stage.
3. Re-run full pipeline.
4. Add hardening action if failure class is recurring.

## 4. Validate

- Local reproducibility status
- CI green status
- Regression checks complete

## 5. Report

- root cause
- fix applied
- residual risk
- follow-up hardening issue (if needed)
