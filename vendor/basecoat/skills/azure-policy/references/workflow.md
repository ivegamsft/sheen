# Azure Policy — Authoring Workflow

1. **Identify governance requirements** — determine the control objective (tagging,
   region restriction, SKU allowlist, encryption, diagnostic settings, etc.) and the
   appropriate policy effect (`Deny`, `Audit`, `AuditIfNotExists`, `Modify`, or
   `DeployIfNotExists`).

2. **Author the policy definition** — use `policy-definition-template.md` to produce
   a well-formed JSON definition with `policyRule`, `parameters`, display metadata,
   and framework mapping annotations.

3. **Bundle into an initiative** — use `initiative-definition-template.md` to group
   related definitions into a policy set with shared parameters and assignment defaults.

4. **Produce remediation tasks** — for `DeployIfNotExists` policies, use
   `remediation-task-template.md` to define the deployment template, managed identity
   scope, and remediation trigger conditions.

5. **Generate compliance queries** — use `compliance-report-template.md` to produce
   Azure Resource Graph and KQL queries that surface non-compliant resources, trend
   over time, and map findings to framework controls.

6. **Map to regulatory frameworks** — annotate each policy definition with the
   applicable CIS Benchmark, NIST 800-53, or ISO 27001 control identifiers so
   compliance evidence is traceable.
