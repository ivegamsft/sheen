---
name: "<agent-name>"
description: "<One-line description with trigger phrases for discovery.>"
tools: [read_file, write_file, list_dir, run_terminal_command, create_github_issue]
---

# <Agent Display Name> Agent

Purpose: <one-sentence statement of what this agent does and why it exists.>

## Inputs

- <Input 1 — what the operator provides>
- <Input 2>
- <Input 3>

## Workflow

1. **<Step name>** — <what the agent does in this step. Keep to 1–3 sentences.>
2. **<Step name>** — <next step.>
3. **<Step name>** — <next step.>
4. **<Step name>** — <next step.>
5. **Review and validate** — verify the output meets acceptance criteria before delivering.
6. **File issues** — create issues for any gaps or debt discovered. See GitHub Issue Filing.

## <Domain Section 1>

- <Guidance, rules, or patterns specific to this agent's domain.>
- <Keep each bullet actionable and concrete.>

## <Domain Section 2>

- <Additional domain guidance.>

## GitHub Issue Filing

File a GitHub Issue immediately when any of the following are discovered. Do not defer.

```bash
gh issue create \
  --title "[<Category>] <short description>" \
  --label "<label-1>,<label-2>" \
  --body "## <Category> Finding

**Category:** <finding type>
**File:** <path/to/file.ext>
**Line(s):** <line range>

### Description
<what was found and why it is a risk>

### Recommended Fix
<concise recommendation>

### Acceptance Criteria
- [ ] <criterion 1>
- [ ] <criterion 2>

### Discovered During
<feature or task that surfaced this>"
```

Trigger conditions:

| Finding | Labels |
|---|---|
| <Finding description> | `<label-1>,<label-2>` |
| <Finding description> | `<label-1>,<label-2>` |

## Model

**Recommended:** gpt-5.3-codex
**Rationale:** <Why this model fits the agent's workload>
**Minimum:** gpt-5.4-mini

## Output Format

- <Describe the deliverable format.>
- <Describe any required metadata or summaries.>
- <Describe how issues should be referenced in output.>

## Allowed Skills

*(none)*

<!-- List skills by folder name if this agent is permitted to invoke them, e.g.:
- agent-design
- api-design
If this agent does not invoke any skills, keep "*(none)*" above and add a negative constraint sentence below. -->
