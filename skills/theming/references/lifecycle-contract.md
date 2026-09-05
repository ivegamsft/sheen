# Theme lifecycle: shared audit and generation contract

Read this before acting. These are logical records and decision rules, not a
required schema, path, language, renderer, font bundle, palette, or file format.
Use the downstream's existing records and supported mechanisms. The companion
[worksheet](../templates/lifecycle-record.md) is optional storage guidance.

## 1. Establish authority and scope

Precedence: accepted downstream brand/design system/product decisions; current
artifact evidence and applicable selections; Experience Blueprint needs;
component/layout catalogs and platform conventions; neutral exploration aids.
Mandatory accessibility, permitted font use, privacy, and disclosure constraints
apply at every level. Record and resolve conflicts under downstream policy;
do not silently replace an accepted brand or waive a mandatory criterion.

Capture the task mode (audit, compare, generate, select, apply, revise), target
surfaces/contexts, required modes/states, capabilities, and success criteria.
Use safe representative content, never require sensitive production data or
send it to an unapproved service. Existing dashboard surfaces may be sampled;
their reporting/data semantics are not theme responsibilities.

## 2. Candidate and comparison

For each candidate record stable app identity, exact revision, friendly name,
purpose, audience/context, use/do-not-use guidance, accepted source decisions,
rationale, provenance, predecessor/base, mapped visual and typography roles,
intentional exceptions, supported surfaces/modes/states, limitations, lifecycle
conditions, unresolved constraints, and evidence references.

Discover by purpose, audience/context, surface/mode, maturity/decision status,
and limitations. Inspect accepted candidates before inventing a direction.
Use `design-exploration` for grounded alternatives, `brand-identity` for identity
constraints, `typography` and `font-mapping` for role and font evidence.
Names are app-specific aids, not imported aesthetics or substitutes for mapping.

Freeze a comparison manifest shared by every candidate:

- Target/platform, content revision, viewport or page conditions, modes, states,
  scale, rendering mechanism/version, font conditions, and applicable criteria.
- Representative hierarchy, dense text, headings, actions, feedback, constrained
  spaces, long/localized labels, required scripts, fallback; numeric/code content
  where relevant. Component semantics, behavior, and layout structure stay fixed.
- Relevant default/hover/focus/disabled/error/etc. states for interactive targets.
  For static documents mark interaction not applicable with a reason; do not
  fabricate controls. Require only downstream-required modes, not a fixed trio.
- Per-candidate evidence references and rendered/simulated/unrendered status,
  revision/scope, limitations, failures, and unavoidable condition differences.

Evaluate all candidates against the same criteria. Do not hide an unsupported
mode, failed state, or unfavorable sample. A comparison with material differences
is provisional until reconciled; document why any remaining difference is fair.
Without a supported preview mechanism, offer a logical comparison and unverified
preview plan. Do not install tools/fonts silently or claim visual readiness.
Required visual evidence stays unknown/blocking until supplied and reviewed.

## 3. Selection and applicability

A selection references an exact candidate revision, surfaces, modes, states,
contexts, rationale, assessed/rejected alternatives (only if assessed), evidence,
constraints/exceptions/questions, authority source/status under downstream policy,
replaced decision, and reassessment triggers.

Do not infer selection from appearance, silence, or a suggested name. Absent or
conflicting authority leaves selection pending; non-destructive proposals may
continue. Explicit downstream policy may delegate selection to an agent.
Use `design-debate` for material uncertainty, not to manufacture alternatives
for an unchanged approved choice.

Resolve identity and revision together; retaining an older revision does not
invalidate a unique exact match. Duplicate records for the same identity and
revision need resolution before reuse.

For approved reuse record the comparison of revision, scope, brand constraints,
capabilities, and mandatory evidence with the prior decision. Reuse without a
redundant prompt only if still applicable. A change triggers applicability
review, not automatic approval transfer. Record a justified bounded scope if
unaffected consumers can retain approval; otherwise reassess decision/readiness.
Never rewrite prior selections to make new evidence appear previously approved.

## 4. Readiness and impact

Readiness references the selection/revision/scope and a requirement register.
For every requirement record mandatory/optional, criterion, scope/mode/state,
observations/measurements, evidence reference and conditions, status **pass,
fail, unknown, or justified not-applicable**, findings and owner.
An omitted mandatory check is unknown, not a pass. Unjustified N/A is unknown.
Stale, wrong-revision, or wrong-scope evidence cannot clear a gate.

| Area | Required work and owning specialist |
|---|---|
| Semantic mapping | Map visual/type roles to existing semantic keys; report unmapped roles and collisions. Preserve keys. Delegate missing concepts to `design-tokens` under downstream conventions. |
| Target capability | Verify the supported rendering/change mechanism expresses each mapped role. Unsupported expressions need an explicit resolution/handoff, not a success-shaped approximation. |
| Typography | `font-mapping` inventories availability and permitted use; `typography` reviews required weights/styles/scripts, fallbacks, role preservation and representative fit. Substitution is not equivalence. Unknown license or missing mandatory glyph/weight blocks until acceptable evidence or authorized fallback exists. |
| Accessibility | `color-contrast-check` evaluates actual required foreground/background/state/mode pairs. Distinguish normal text (AA 4.5:1), large text (3:1), applicable non-text boundaries/focus information (3:1), and meaningful non-color cues. Record exemptions and stricter criteria. Broader target behavior goes to `accessibility-audit`. |
| Visual evidence | `design-review` evaluates representative surfaces; `visual-regression` supplies available rendered comparisons. Simulated/unrendered evidence cannot stand in for required visual evidence. Palette ratios alone never establish whole-artifact WCAG conformance. |
| Impact | Enumerate affected surfaces and component/layout references, deliberate exceptions, unchanged semantics/behavior/content, migration consumers and bounded change scope. |
| Recovery | Identify previous accepted state, recovery intent/mechanism and authorization boundary; preserve unrelated work. Missing recovery evidence blocks readiness when mandatory. |

Any mandatory fail or unknown blocks readiness even for an approved selection.
Record optional failures honestly. Selection, readiness, change authorization,
and deployment authorization are separate facts.

## 5. Application, review, and history

Before changes, verify current readiness matches selection and exact authorized
revision/targets/modes/change mechanism. Never expand scope using an old approval.
Without implementation rights/capability, produce a bounded handoff to
`design-handoff` / `design-to-code`, not an applied claim. Change only authorized
targets through downstream-owned mechanisms; preserve unrelated work, semantic
keys, content, behavior, and structure. No new runtime adapter is implied.

Record actual changes per target, unchanged/unattempted/failed targets, before
and after evidence, exceptions, unresolved findings, and review outcome.
Review representative affected surfaces and all required modes/states.
Partial application or failed/unknown post-review withholds completion; keep
**Applied** alongside **Blocked** when changes actually occurred. Record remaining
risk and recovery path. Recovery itself needs appropriate downstream authority;
do not pretend it happened or overwrite unrelated changes. Repeating an unchanged,
reviewed application should be a no-op with an applicability record.

Conditions: **Proposed** (not accepted), **Selected** (authorized decision),
**Ready** (mandatory gates clear), **Applied** (actual changes),
**Reviewed** (post-change evidence supports the recorded outcome),
**Superseded** (replacement for specified use), **Blocked** (next step prevented).
These can coexist; a failed review is not successful completion.

For custom requests choose and justify:

- **Reuse:** an approved applicable candidate meets the brief; no gratuitous edits.
- **Extend:** the semantic purpose remains valid but expression/support needs a
  revision; identify base and affected consumers.
- **Create:** no suitable base meets an unmet app need; ground it in accepted
  decisions through exploration and specialists, not copied names/aesthetics.

All three use the same records and gates. An unmet creation/extension prerequisite
blocks readiness and completion
even if selection, change authorization, or post-review otherwise passes. Retain
actual applied history when such a violation is discovered. Preserve predecessor and decision
history, identify affected consumers, invalidate affected evidence on revision,
and record migration/recovery guidance. Superseding one use does not silently
retire unaffected uses; bounded reassessment needs explicit justification.

## 6. Audit and handoff

Audit inventories observed usage and maps it to known candidates/decisions.
Record uncovered surfaces/states and uncertain mappings. Missing records/previews
are not proof the theme is absent. Each finding carries observation/evidence,
confidence, impact, affected artifacts, recommended action, and owner.
Classify a variant as legitimate only with applicable exception/decision evidence;
unapproved divergence is drift, insufficient evidence is unresolved. Audit does
not change targets unless a separate authorized implementation task is established.

`design-system-architect` owns composition. Brand, token, typography, contrast,
review, and implementation specialists retain their authority. Experience
Blueprint references selected identity/revision, decision/evidence, readiness,
authorization limits, and affected component/layout catalog entries; do not copy
catalogs into it. Brand-only requests go to `brand-identity`/`brand-voice-tone`;
reporting-only requests go to `data-visualisation`. Supported non-reporting
documentation diagrams go to `documentation-diagram`, not broad theming.
