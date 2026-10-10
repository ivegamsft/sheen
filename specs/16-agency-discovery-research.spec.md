# Spec 16 — Agency Discovery and Evidence-backed Research

> Normative extension for #292 within Wave 18 #291. Written before skill
> implementation. Scope: preparing discovery and synthesizing authorized inputs;
> no actual interviews, imported external content, or invented research.

## 1. Bounded design decision

Extend `user-research` as the discovery/research owner, with skill-local Markdown
contracts and reusable blank templates. Do not add a new skill, agent, external
methodology, runtime schema, or automated interviewing service. Markdown keeps
the brief portable without tooling dependencies; review remains human-governed.
`design-bootstrap` consumes discovery for greenfield foundations;
`design-exploration` consumes evidence for divergent concepts, not final approval.
The existing `ux-designer` coordinates research-to-design handoffs.

Inventory prior art: `user-research` already promises planning, interview/persona
synthesis and usability protocols, plus governance findings, severity,
remediation owners and decision logs. Preserve these capabilities.
`design-bootstrap` retains tokens/themes, component/IA foundations, accessibility
and staged rollout. `design-exploration` retains creative calibration,
anti-template comparison, rejected alternatives, risk/dependency notes and
accepted-decision authority. Do not collapse these workflows into interviews.

## 2. Discovery brief

`user-research` MUST read/apply its local contract before drafting or synthesis.
The portable brief MUST record client/product context, decision and success
criteria, scope/exclusions, audience and recruitment/accessibility constraints,
known inputs, interview questions, usability task/protocol when applicable,
authorized method, roles, schedule, and deliverable destination.
Absent evidence it MUST output a plan, not claim a completed study.

Assumptions and unknowns MUST be explicit, separately identified, and carry
impact, validation question/method, owner and checkpoint. Client assertions are
attributed stakeholder inputs, not automatically user evidence.

## 3. Evidence and findings contract

Use stable local IDs for evidence, findings, assumptions, unknowns and decisions.
Evidence records MUST include an authorized source reference and exact locator,
date/version, method/context, access/use authorization and sharing restrictions.
Private raw evidence stays in its approved store; shared deliverables use
minimized/redacted locators and summaries, never secrets or participant identity.

Each finding MUST distinguish observation from interpretation and recommendation,
link to available authorized evidence IDs/locators, and state confidence with
rationale, limitations, conflicting evidence, severity/impact, owner and closure
criteria. Missing, inaccessible, stale, withdrawn or unauthorized support makes
the claim unresolved or a hypothesis, not an evidence-backed finding.
Personas and synthesis MUST retain provenance and limits; hypothetical personas
are labeled hypotheses and never passed off as observed participants.
Do not infer prevalence or representativeness from qualitative anecdotes.

## 4. Consent, privacy and non-fabrication

Before collection/use, document purpose, voluntary informed consent or applicable
documented authorization, recording permission separately, access/sharing limits,
retention/deletion owner and withdrawal handling. Unknown permission blocks that
activity; planning may continue with a clearly marked gap.
Do not contact participants, record, scrape, publish or transfer data merely
because a brief exists. Explicit authorization is required for those activities.
Never fabricate interviews, quotes, metrics, consent, source access or validation.
Never promise legal compliance or anonymization merely because names are removed.
Withdrawn evidence MUST be removed from active synthesis and dependent findings
reassessed; retain only policy-permitted non-sensitive change history.

## 5. Handoffs and acceptance

Handoff MUST carry brief revision/scope, evidence and finding IDs, assumptions,
unknowns, restrictions, accepted decisions and unresolved conflicts, destination
owner, next validation and acceptance checkpoint. No raw participant data by
default. Findings do not authorize implementation or final design sign-off.
Use `information-architecture` for grouping/navigation structure,
`web-usability-review` for heuristic-only evaluation, `design-exploration` for
concept options, `design-bootstrap` for greenfield setup, and
`experience-blueprint`/`wireframing` for downstream journey/screen artifacts.

Skill bodies MUST remain <=2500 LF characters; detail belongs in local
references/templates with required read/apply links. Frontmatter and routing
evals MUST preserve old triggers and add realistic discovery/evidence requests,
with >=3 positive and >=2 negative scenarios per changed skill.
Source-checkout tests MUST verify template fields, portable links, boundaries,
handoff ownership and prior capability preservation; existing frontmatter,
routing and warning checks MUST pass. Structural checks are not LLM routing
execution, evidence authenticity verification, or user validation.
Metadata and directly related skill catalog entries are updated with this
workstream. The parent integrates shared release documentation and CI registration.
