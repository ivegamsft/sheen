# Experience Blueprints

An Experience Blueprint is a product-experience contract. It
connects brand, voice, information architecture, layouts, pages, wireframes,
navigation, and user flows so teams and agents can audit or create an
application without producing disconnected documents.

## When to use one

Use **audit mode** when an application already exists and you need to inventory
the experience, expose inconsistencies, and prioritize remediation.

Use **generate mode** when a product brief exists but the experience structure
does not. The output is ready for design review and frontend handoff, not
production UI code.

Both modes produce the same logical artifact set. Audit mode additionally
produces an evidence register and findings report.

The contract is implementation-neutral. A downstream can represent it in
Markdown, YAML, JSON, a database, a design tool, a documentation system, or
another format that preserves the required concepts and relationships. Sheen
does not select the language, framework, storage model, or rendering tool.

Start with the downstream's own design system, product evidence, user research,
and platform conventions. External galleries and libraries can inspire catalog
structure, vocabulary, metadata, and composition, but they are not templates to
copy and do not override an application's accepted design system.

## How the pieces fit

```text
Product intent and evidence
          |
          v
Experience archetype selection
          |
          v
Brand + voice + IA
          |
          v
Layouts -> pages -> wireframes
          |
          v
Navigation and end-to-end flows
          |
          v
Validation -> documented experience -> implementation handoff
```

The blueprint is an index and relationship model. Existing sources remain
authoritative:

- token values stay in DTCG tokens and `DESIGN.md`;
- creative direction stays in `AESTHETIC-DIRECTION.md`;
- canonical terminology stays in `.lexicon.md`;
- component contracts stay in the component inventory and specifications;
- reusable interaction compositions stay in the pattern library.

## Archetypes are starting constraints

Select one primary archetype and optional supporting archetypes:

| Archetype | Use it for |
|---|---|
| Marketing home | Product/company home pages that explain value and build trust |
| Campaign splash | A focused launch, event, announcement, or conversion page |
| Commerce | Catalog, product comparison, purchase, and post-purchase journeys |
| Dashboard | Monitoring summarized information with filtering and drill-down |
| Control tower | Operational awareness, prioritization, coordination, and resolution |
| Workflow app | Sequential business tasks, reviews, approvals, and completion |
| Docs/knowledge | Search, browse, learn, apply, and provide feedback |
| Admin/settings | Safe configuration, policy, permissions, and preferences |

Archetypes do not choose an aesthetic. A high-density control tower and a calm
consumer dashboard may share page moments while using different brands,
layouts, density rules, and interaction patterns.

## Audit an existing experience

1. Establish scope: platforms, routes, roles, journeys, and environments.
2. Inventory code, screenshots, live pages, navigation, analytics, tests, and
   current design documents.
3. Record evidence with capture date and confidence.
4. Populate the blueprint with what is observed, not what was probably
   intended.
5. Trace every route into IA, layout, page, navigation, and flow relationships.
6. Score maturity and log evidence-backed findings.
7. Separate remediation into contract fixes, design-system fixes, page fixes,
   and implementation fixes.

Audit output should answer:

- Which pages and flows exist, and which are unreachable or incomplete?
- Does navigation match the information architecture?
- Do layouts and page states remain coherent across breakpoints?
- Does product copy follow the intended voice and terminology?
- Where do brand, component, or pattern treatments drift?
- Which critical tasks lack error, cancellation, or recovery paths?

## Generate a new experience

1. Write the brief: audiences, jobs, constraints, platforms, and measures.
2. Select and justify the archetype composition.
3. Explore candidate IA and layout directions.
4. Use a structured design debate to select the direction.
5. Define brand and voice references, then IA and navigation.
6. Define layout structures before individual pages.
7. Define pages and all required data/permission states.
8. Add low-fidelity wireframes and end-to-end flows.
9. Validate references, coverage, and specialist constraints.
10. Generate the summary and handoff package.

## Minimum viable blueprint

For a small application, start with:

- a brief;
- an experience index;
- an IA artifact;
- one layout;
- a page inventory with state coverage;
- the top three user flows.

Add detailed brand, voice, and wireframe artifacts by reference when the project
already has accepted sources. Do not copy those sources merely to fill every
folder.

## Orchestrator skill and agent

The `experience-blueprint` skill is the single orchestrator entry point for
both modes. It does not reimplement brand, IA, accessibility, component, or
frontend expertise — it populates the experience index and delegates each
domain artifact to the specialist skill that already owns it (see the
skill's `Delegates / pairs with` list). The `experience-architect` agent
composes this skill for full-experience requests and routes narrower
requests to the neighboring agent whose mandate actually owns them:

| Request shape | Routes to |
|---|---|
| Full experience audit or generation (pages, flows, navigation) | `experience-architect` |
| Brand or voice only, no page/flow scope | `brand-steward` |
| IA or taxonomy only, no page/flow scope | `information-architect` |
| Single component, pattern, or interaction state | `ux-designer` / `component-spec` |
| App-specific component gallery audit/selection | `app-component-catalog` (composed by `design-system-architect`) |
| App-specific layout gallery audit/selection | `app-layout-catalog` (composed by `ux-designer`) |
| Runtime UI implementation | `design-to-code` / `frontend-dev` |

Starter reasoning templates for each mode live in
`templates/experience-blueprint/`: `experience-index.md`, `archetypes.md`,
`audit-workflow.md`, `generation-workflow.md`, and `handoff.md`. Layout and
page-component selection during generation delegate to the app-specific
`app-layout-catalog` and `app-component-catalog` galleries rather than
inventing structure inline.

## Contract checks

`scripts/audit-experience-blueprint.ps1` implements the required checks from
`specs/10-experience-blueprint.spec.md` §12: identifier uniqueness, every
page's layout reference, every flow step's page/external-touchpoint
reference, responsive breakpoint coverage, required page-state coverage,
audit-finding evidence/artifact references, documentation provenance, and
archetype-required-moment coverage. It also warns on orphan pages and flows
missing a recovery/cancellation path.

```console
pwsh scripts/audit-experience-blueprint.ps1 -Path <your-blueprint>.json
```

The script's JSON input is **one illustrative example representation**, not
a mandated schema — see `tests/fixtures/experience-blueprints/README.md`.
Represent the same concepts and relationships in whatever format your
project already uses, and adapt the checks accordingly.

### Portable wireframe intake

Both modes accept `sheen-wireframes/v1` models as optional prototype evidence.
Keep page/screen/flow IDs unchanged; a screen is a state of one indexed page.
Existing layout, theme and component decisions remain authoritative.
`design-handoff` carries implementation/spec destinations, positional mappings
for each mock input/action, ordered blueprint flow-step mappings, omitted-state
reasons and explicit simulation limits. Audit simulations remain proposed,
not observed production behavior.

The complete portable example is
`skills/design-handoff/templates/wireframe-blueprint.json`; detailed semantics
live in that skill's `references/wireframe-contract.md`. It illustrates an
optional attachment to the existing reference JSON, not a new mandatory schema.
The read-only helper reuses `wireframing`'s model validator:

```powershell
python .\skills\design-handoff\scripts\validate-wireframe-handoff.py --input .\skills\design-handoff\templates\wireframe-blueprint.json --original-model .\skills\wireframing\templates\task-flow.json
```

**SOURCE CHECKOUT ONLY:** blueprint-wide audit and regression commands below
are separate from distributed skill usage. The regression script is stripped
from production publication and is not available in synced consumer skills.

```powershell
pwsh .\scripts\audit-experience-blueprint.ps1 -Path .\skills\design-handoff\templates\wireframe-blueprint.json -OriginalModelPath .\skills\wireframing\templates\task-flow.json
python -B .\scripts\test-wireframe-handoff.py
```

Consumers sync sibling `design-handoff` and `wireframing` skills for the optional
Python helper; no source-repository tools or packages are needed for its checks.
The source blueprint auditor invokes the portable checker only when attachments
are present (Python 3 required then); legacy audits need no Python.
Attached handoffs require separately supplied approved original model baselines;
missing baselines or changed decoded model content block before mapping checks.
Callers must obtain baselines from trusted immutable revisions and record their
approval/provenance, not extract them from editable handoffs or trust embedded
digests. The checker verifies content, not approval authenticity.
Each attachment records `baseline` revision, approval evidence references and a
canonical digest checked against the independent original. JSON key order and
source LF/CRLF whitespace do not change that digest; the skill-local contract
defines its fixed ASCII/compact/sorted-key normalization. Sample approval
evidence is synthetic/example only. Missing provenance blocks validation.
Repeat
`--original-model` per attachment or pass an array to `-OriginalModelPath`.
Use `python3` on Linux/macOS; the auditor selects the platform interpreter.
Successful attached-model checks remain structural-only: the auditor records a
non-failing `wireframe-handoff-boundary` warning carrying review status and no
production approval/write authorization. Console output includes the checker
limitations; `-Json` emits the same findings with structured `structuralOnly`,
`noProductionApproval`, `noWriteAuthorization` and per-artifact review details.
`-Json` takes precedence over `-Quiet`. Valid structure still exits zero; legacy
blueprints without attachments acquire no new boundary warning.
Blueprint-wide checks remain separate. A structural pass never proves external
spec acceptance, user-task success, WCAG conformance or production readiness.
The sample intentionally has pending review and proposed component references.
Mock controls/CSS/JS and success/error labels are not production validation,
persistence, authentication, payment, network or business side effects.
Accepted specs go to `design-to-code` for scaffolding; integrations need their
own contracts/tests and `frontend-dev`. No handoff implies write authorization.

## End-to-end scenarios

- **Audit scenario** — `tests/fixtures/experience-blueprints/valid-sample.json`
  is a complete commerce-archetype audit: five pages covering every required
  commerce moment (discovery, detail, cart, checkout, confirmation), a
  purchase flow with recovery and cancellation paths, an evidence-backed
  finding, and a source-linked summary. It passes the contract checks with
  zero findings.
- **Broken scenario** — `tests/fixtures/experience-blueprints/invalid-sample.json`
  is the same shape with deliberate violations (a duplicated identifier, a
  page pointing at a missing layout, a flow step pointing at a missing page,
  a responsive page with no breakpoints, a missing required state, a finding
  citing missing evidence, an unrepresented required moment, and an orphan
  page) so downstream teams can see exactly what the checker catches.

## Review checklist

- Every page has a purpose, route, layout, states, and transitions.
- Every flow step resolves to a page or declared external touchpoint.
- Navigation destinations exist and are reachable.
- Mobile behavior is an explicit reflow, not "same as desktop."
- Brand and voice examples cover normal, empty, error, and success moments.
- Audit claims cite evidence and confidence.
- Generated proposals mark assumptions and unresolved research questions.
- Diagrams illustrate the model but do not replace structured source.

The normative schema, workflow, validation, and acceptance criteria are in
`specs/10-experience-blueprint.spec.md`.
