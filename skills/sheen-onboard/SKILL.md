---
name: sheen-onboard
compatibility: [github-copilot-cli]
description: "Use when onboarding a new consumer repository to the basecoat-sheen design governance framework. USE FOR: run the full 5-phase sheen consumer lifecycle (integrate, onboard, inventory, audit, use), bootstrap a .sheen.yml config, run sync against basecoat-sheen, generate an onboarding health report. DO NOT USE FOR: implementing product features, writing application business logic, deploying infrastructure."
category: development
metadata:
  category: development
  maturity: stable
  audience:
    - developer
    - designer
allowed-tools: []
---
# Sheen Onboard Skill

Orchestrates the sheen consumer onboarding lifecycle from first sync through first validated use.

## Workflow
1. Bootstrap or re-sync the consumer repo if sheen assets are not yet present, then prompt the user to reset Copilot context so the synced skill becomes available.
2. Generate or refine `.sheen.yml` for the requested lifecycle scope, including upstream source/ref and whether token materialization is required.
3. Run the relevant phases: integrate, onboard, inventory, audit, and first-use validation.
4. Verify phase gates with the produced artifacts and checks, including `.sheen/manifest.json`, token output, inventory results, and audit status.
5. Return a phase-by-phase report with gate status, blockers, and the next recommended action.

## Guardrails
- Use this skill only for onboarding or validating a consumer repo against sheen governance, not for feature delivery or unrelated product code changes.
- Do not claim bootstrap or sync succeeded unless the required artifacts exist and Copilot reset instructions were provided.
- Do not advance past audit when critical validation failures remain unresolved.
- Keep detailed lifecycle prompts and bootstrap walkthroughs in `docs/guides/consumer-lifecycle.md` and `docs/guides/prompts/generated-sample-prompts.md`.

## Output
- A `.sheen.yml` starter or focused onboarding updates for the requested phase.
- A concise onboarding report summarizing completed phases, gate state, warning/critical counts, and follow-up actions.

## Delegates / pairs with
- `design-system-architect` for inventory and token coverage assessment.
- `accessibility-auditor` for contrast and accessibility-related audit gates.
- `design-reviewer` or other downstream sheen agents for first-use validation after onboarding succeeds.
