# Style guide authoring contract

Use this self-contained contract with `SKILL.md` when compiling, reviewing,
refreshing or checking a guide. The stable skill name is
`style-guide-authoring`; do not create a `brand-guide-html` skill, alias or
parallel workflow.

## Intent and format

Classify the request before producing output:

| Intent | Behavior |
|---|---|
| Audit | Review a supplied guide against applicable contracts. Return findings, severity, remediation owners and a decision log. Do not create, refresh or publish artifacts. |
| Template | Produce an original neutral shell labeled `TEMPLATE` with visible placeholders and an input checklist. Do not invent values or approvals. |
| Generate | Populate included modules from approved inputs. Missing, proposed or unknown decisions remain visible and unresolved. |
| Refresh | Reuse freshness evidence for an existing guide. CURRENT is a no-op; STALE/UNKNOWN remains a report-only PARTIAL result until separately authorized regeneration updates owned content and evidence. Preserve stable IDs and consumer additions; block when ownership is unclear. |
| Check | Compare an existing generated guide and its recorded provenance with current authorized inputs and current evidence for guide-owned artifacts. Report CURRENT only when both comparison inputs are available and unchanged; report STALE for verified differences and UNKNOWN when current inputs or owned-artifact evidence are unavailable. Do not mutate guide files, sources, metadata or timestamps. |

Select delivery format independently from intent. An explicit HTML request selects the HTML profile. A refresh keeps the existing guide format unless the request names a replacement. Otherwise authoring defaults to Markdown. Do not create both Markdown and HTML unless explicitly requested.

## Output requirements

Authoring must return the guide itself, not only a governance report. Include:

- selected guide content or template content
- module/input status summary
- provenance for approved inputs, including source identifier, revision or digest, approval state and supported module/rule
- resource inventory and missing-resource slots
- review checks with PASS, FAIL, UNKNOWN or N/A plus rationale
- overall state: TEMPLATE, DRAFT, BLOCKED or READY

Audit and check modes return reports only. A successful audit or CURRENT freshness check does not publish, write, approve or promote a guide to READY.

## State precedence

Use BLOCKED first for unsafe content, source leakage, ownership conflicts or contradictory approved rules. Template mode is TEMPLATE. Otherwise unresolved inputs, proposals, stale evidence or unknown required checks produce DRAFT. READY requires approved complete included modules, required review evidence and no blocking findings.

## Write boundaries

Artifact writes require an explicit destination and permission to create or replace named guide-owned files. Never write for audit-only or check requests. Never update `metadata.style_guide_url` or `metadata.brand_guide_url` as part of authoring; record a proposed URL only as a handoff. Publishing, docs-platform configuration and portable HTML packaging are separate authorizations.
