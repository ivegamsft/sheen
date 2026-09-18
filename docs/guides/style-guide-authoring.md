# Style Guide Authoring

Use `style-guide-authoring` when a downstream repo needs a governed guide from
approved guidance. The skill keeps Markdown as the default deliverable and adds
portable HTML only when the request explicitly asks for it.

## What is available

| Request | Result |
|---|---|
| Generate or template without a format | Markdown guide or neutral template |
| Explicit offline HTML | Self-contained `.html` file, default 5 MiB budget |
| Explicit local bundle | Entry HTML plus relative `assets/` files, default 25 MiB budget |
| Refresh | Current guides are no-op; stale or unknown evidence is reported without writes |
| Check freshness | Read-only CURRENT, STALE, UNKNOWN or BLOCKED report |
| Audit | Findings and decision log only; no artifact writes |

HTML output is a delivery profile, not publication. It does not update
`metadata.style_guide_url`, upload files, change application styles or approve
identity decisions. Those actions require separate authorization.

## Consumer delivery

Sync the complete skill folder, not individual source files:

```yaml
source: https://github.com/ivegamsft/sheen.git
ref: main
skills:
  - style-guide-authoring
agents:
  - design-reviewer
templates:
  - style-guide
```

After sync, a consumer repo should have:

```text
.github/skills/style-guide-authoring/SKILL.md
.github/skills/style-guide-authoring/eval.yaml
.github/skills/style-guide-authoring/references/
.github/skills/style-guide-authoring/scripts/
.github/skills/style-guide-authoring/templates/guide-outline.md
.github/agents/design-reviewer.agent.md
sheen/templates/style-guide/
```

The copied skill-local scripts are sufficient for portable HTML and freshness
checks. Consumers do not need source-only top-level generators such as
`scripts/build-design-md.ps1` to use the copied skill folder.

## Evidence

The delivered contract is covered by synthetic fixtures only:

| Area | Evidence |
|---|---|
| Input mapping, freshness, no-op refresh and stale/unknown handling | `scripts/test-guide-inputs.ps1` |
| HTML profiles, byte budgets, safe assets, ownership and browser acceptance | `scripts/test-guide-html.ps1`, `tests/visual-regression/style-guide-html.spec.js` |
| Routing scenarios, complete payload metadata and synced consumer execution | `scripts/test-guide-consumer-delivery.ps1` |

These checks distinguish deterministic local evidence from unresolved specialist
review. A generated guide remains `DRAFT` unless required review evidence exists;
failed or unexecuted checks cannot produce `READY`.
