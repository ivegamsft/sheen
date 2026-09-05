# T01–T14 worked contract evidence

These fixtures demonstrate logical decisions, **not an actual rendered app,
agent-run transcript, font license, or downstream schema**. All evidence IDs
starting `synthetic-`, and all other supplied measurements/observations, are
illustrative inputs. They must never be reused to clear a real readiness gate.

## Reproduce and inspect

```powershell
pwsh -NoProfile -File scripts\test-theme-lifecycle.ps1 -OutFile dist\theme-lifecycle-evidence.json
```

Run from the repository root. PowerShell is the existing validation mechanism;
no new framework/dependency is introduced. CI runs the same script.
Successful CI runs publish the expanded report as `theme-lifecycle-evidence`
(seven-day retention); committed inputs/expected outputs remain the durable,
reproducible coverage source.

- [baseline.json](baseline.json) supplies a safe staff-review brief, two distinct
  candidate revisions with identical content/conditions, discovery metadata,
  existing semantic keys, policy-delegated selection, requirement observations,
  measured normal/large/non-text pairs, recovery intent, and history.
- [scenarios.json](scenarios.json) supplies per-case input changes and independently
  authored expected outputs. Objects deep-merge the baseline; arrays replace it;
  null removes the value (a missing mandatory row still blocks).
- [test-theme-lifecycle.ps1](../../../scripts/test-theme-lifecycle.ps1) evaluates
  supplied facts into comparison, applicability, readiness, and application
  decisions. It never renders, installs, writes target files, or calls an agent.
- The optional `dist` report contains **expanded supplied input + expected +
  actual output** per case. Console output reports assertion and rejection counts.
  Each expected-output oracle must reject a deliberately incorrect output field;
  this tests the assertion path, not visual detection or autonomous agent compliance.

For example, T08 replaces the pair list with the reported failing error-state
normal-text pair (3.2:1 versus 4.5:1). Selection remains reusable, but readiness
is blocked by `contrast:error:3.2<4.5`; application remains a handoff. T10 supplies
an actual changed queue, failed detail target and failed review: the evaluator
retains `queue` in changed targets and Applied history, excludes detail from
changed targets, withholds completion, and retains recovery intent.

## Coverage map and expected decisions

| Spec | Supplied evidence / scenario branches | Asserted output / negative behavior |
|---|---|---|
| T01 | `comparable`: sample-1 shared dense text, hierarchy, long action, feedback, localization/fallback; `mismatched-content`: target changes to sample-2 | Comparable versus provisional/blocked; exact identity, purpose, maturity, limitations and preview status emitted beside each candidate |
| T02 | `interactive`: default/focus/error/disabled; `static`: no controls with explanation; `unsupported-mode`: adds required dark mode | Covered versus justified N/A; unsupported mode blocks and scope reassesses |
| T03 | `unavailable-preview` and `simulated-preview` replace rendered status | Logical-only comparison, visual-evidence blocker; no application |
| T04 | Explicit delegated policy, exact decision/revision/evidence; retained older revision and duplicate exact revision; no write grant; separate grant plus actual changes/review; unchanged-reviewed repeat | Reuse unique exact revision despite retained predecessor; reject duplicate exact identity/revision; no redundant prompt; selection alone only handoff; authorized reviewed outcome versus no-op |
| T05 | Changed selection revision or required evidence revision; evidence bound to wrong candidate | Reassess decision/readiness before application; stale evidence cannot clear gates |
| T06 | Accepted brand conflicts; policy authority omitted | Pending, blocked, no changed targets; no invented human or agent approval |
| T07 | Missing font, unknown permission, missing Arabic shaping/weight; alternative branch supplies authorized fallback availability/permission/coverage/fit observations | Block missing evidence; clear only with complete supplied fallback evidence, never install |
| T08 | Required error pair 3.2 < 4.5; missing permission row; unjustified N/A fit | Specific blockers; selection does not waive contrast or unknown mandatory evidence |
| T09 | Target probe cannot express focus; semantic heading key missing | Capability or semantic-mapping block; `design-tokens` owns missing concepts, no invented key |
| T10 | Queue changed, detail failed, review failed; missing review; wrong-candidate grant or observed out-of-scope change; changed semantic keys or unrelated behavior in before/after snapshots | Keep actual changes and recovery; Applied + Blocked, completion false; flag authority/preservation violations without erasing changes |
| T11 | Suitable approved theme; unmet compact expression with valid base; unmet audience without valid base; populated new candidate and absent grounding; invalid custom prerequisites with independently approved application/no-op | Reuse / extend / create with rationale; ordinary selection/visual gates also block populated custom candidate; invalid custom prerequisites block readiness/completion while preserving actual changed targets |
| T12 | New revision affects queue and invalidates preview/font-fit evidence | Preserve predecessor and two prior history entries; identify consumer/stale evidence and reassess |
| T13 | Observed queue has applicable exception; detail diverges without approval; archive lacks observations; unauthorized audit change observed | Variant / drift / unresolved, audit-only, no inferred absence; retain observed actual changes if an audit boundary was violated |
| T14 | Brand-only identity, reporting-only data charts, and non-reporting documentation diagrams | Brand, data-visualisation, and documentation-diagram owners respectively; theme application not in scope, readiness not assessed |

## Reading the model honestly

The evaluator models the supplied fixture facts and finite branches. For example,
`evidenceVersion` is an illustrative applicability fingerprint, and a rendered
preview status is a *supplied* assertion, not evidence produced by this test.
The readiness register's accessibility review covers pair inventory applicability;
the explicit pair rows expose representative measured successes/failures, not
every possible WCAG criterion. The production skill contract requires the real
downstream to obtain and review all required evidence.

No fixture output proves an agent will follow every instruction or that the app
is accessible/visually ready. Routing evals in
[theming/eval.yaml](../../../skills/theming/eval.yaml) separately check discovery.
Real-world previews/dogfood and policy-specific application are still required.
