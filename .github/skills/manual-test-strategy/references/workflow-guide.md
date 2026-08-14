# Manual Test Strategy Workflow Guide

## Workflow

1. **Inventory behaviors**: list all behaviors that could be tested, noting change frequency, business risk, and existing scripted coverage.
2. **Apply the rubric**: classify each behavior using `rubric-template.md`.
3. **Produce artifacts**: charter, checklist, or both depending on what the rubric produces.
4. **Capture evidence**: use `defect-template.md` for any found defects.
5. **Identify automation candidates**: any hybrid or automate-now row that is not yet scripted becomes a backlog candidate.
6. **File GitHub Issues**: for automation candidates using the `gh issue create` pattern defined in the relevant agent.

## Output Expectations

- Every behavior is classified; no implicit scope.
- Evidence is rich enough for a new team member to reproduce findings without tribal knowledge.
- Automation handoff is explicit: candidates are named, prioritized, and tracked as GitHub Issues.
- Artifacts remain stack-agnostic: no tooling-specific references in templates.
