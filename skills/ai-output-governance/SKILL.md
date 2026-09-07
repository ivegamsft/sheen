---
name: ai-output-governance
compatibility: [github-copilot-cli]
description: "Use when reviewing AI-generated UI copy, imagery, or components for bias, hallucination, brand safety, and accessibility compliance. USE FOR: audit AI-generated copy for harmful bias or hallucinated facts, review AI-generated images for brand compliance and representational fairness, flag AI-generated UI components that violate accessibility or token standards, enforce content moderation thresholds before AI output reaches users. DO NOT USE FOR: implementing AI model inference, training data curation, backend ML pipeline design."
category: development
metadata:
  category: development
  maturity: stable
  audience:
    - developer
    - designer
    - content-author
allowed-tools: []
---
# AI Output Governance Skill

Review AI-generated copy, imagery, and UI for bias, hallucination, brand safety, and accessibility before users see it.

## Workflow
1. Identify content type/scope and load downstream brand and AI-content policies.
2. Read and apply the [review contract](references/review-contract.md): dimensions, severity table, scenarios, artifact roles, and schema.
3. Check claims against sources, fairness, brand, accessibility, token compliance, moderation, and disclosure.
4. Record dimension results, findings, severity counts, and a PASS/WARN/FAIL/UNRESOLVED gate; hand off revisions and final QA.

## Guardrails
- Factual inaccuracy, unfair representation, and harmful/explicit/legally risky content are CRITICAL; never silently clear them.
- Brand, accessibility, token, and disclosure failures are MAJOR. Enforce required policy labels; do not invent missing policy or evidence.
- N/A needs an applicability reason. Missing evidence is UNKNOWN; return UNRESOLVED unless a known CRITICAL failure already requires FAIL.
- Review content, not model inference, training data, or backend ML pipelines.

## Output
- Downstream review report using the reference's `audit-report` schema: content type, reviewed dimensions, findings/recommendations, critical/major counts, gate.
- Copy/imagery review, component audit, and disclosure checklist as applicable.

## Delegates / pairs with
- Triggered by: `brand-steward` (brand safety), `accessibility-auditor` (a11y on AI content).
- Feeds: `ux-designer` (revise copy/imagery), `design-reviewer` (final visual QA).
