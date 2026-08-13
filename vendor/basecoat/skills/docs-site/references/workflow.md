# Docs Site — Workflow

## 1. Analyze Docs Structure

Examine `docs_structure` to identify:

- Top-level folders → nav sections
- Key files: README, CHANGELOG, CONTRIBUTING
- Ecosystem signals (PowerShell scripts, Python packages, npm modules) that inform
  the getting-started tab order

## 2. Generate `mkdocs.yml`

Produce a Material-theme config using `theme_color` and `nav_style` with:

- Mermaid superfences (`pymdownx.superfences` + `mermaid` custom fence)
- `search`, `content.code.copy`, and `content.tabs.link` features
- Nav auto-built from the analyzed structure

```yaml
site_name: "<site_name>"
site_url: "<site_url>"
repo_url: "<repo_url>"
theme:
  name: material
  palette:
    primary: "<theme_color>"
    accent: "<theme_color>"
  features:
    - navigation.tabs
    - content.code.copy
    - content.tabs.link
markdown_extensions:
  - pymdownx.superfences:
      custom_fences:
        - name: mermaid
          class: mermaid
          format: !!python/name:pymdownx.superfences.fence_code_format
  - pymdownx.tabbed:
      alternate_style: true
plugins:
  - search
nav:
  - Home: index.md
  - Getting Started: getting-started.md
  # <additional sections from docs_structure>
```

## 3. Generate `docs/index.md`

Landing page containing:

- One-paragraph description of the repository
- A generic Mermaid system-context flowchart (caller customizable)
- A quick-links table pointing to Getting Started and key reference pages

```markdown
# <site_name>

<one-paragraph description>

## Architecture

\`\`\`mermaid
flowchart TD
    User -->|uses| Repo["<site_name>"]
    Repo --> Docs["Documentation"]
    Repo --> CI["CI / CD"]
\`\`\`

## Quick Links

| Page | Description |
|------|-------------|
| [Getting Started](getting-started.md) | Install and first steps |
```

## 4. Generate `docs/getting-started.md`

Tabbed installation guide using `pymdownx.tabbed`, ordered by ecosystem signals:

```markdown
# Getting Started

## Installation

=== "PowerShell"
    \`\`\`powershell
    <install_pattern for PowerShell>
    \`\`\`

=== "Shell"
    \`\`\`bash
    <install_pattern for Shell>
    \`\`\`

=== "npm"
    \`\`\`bash
    npm install <package>
    \`\`\`

=== "pip"
    \`\`\`bash
    pip install <package>
    \`\`\`

## Verify

<verification command or step>

## Next Steps

- [Reference →](reference/index.md)
```

Only include tabs relevant to the detected ecosystem.

## 5. Generate `.github/workflows/docs.yml`

CI workflow that deploys on push to `main` when `docs/**` or `mkdocs.yml` changes:

```yaml
name: Deploy Docs

on:
  push:
    branches: [main]
    paths:
      - "docs/**"
      - "mkdocs.yml"

permissions:
  contents: write

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0
      - uses: actions/setup-python@v5
        with:
          python-version: "3.12"
      - run: pip install mkdocs-material
      - run: mkdocs gh-deploy --force --no-history
```

## 6. Generate `docs/reference/asset-catalog.md` (Optional)

Only generated when `asset_types` is provided. For each asset type:

- Read frontmatter `description` fields from all matching files
- Group entries by category or type
- All links must use absolute GitHub URLs (never relative markdown paths)

```markdown
# Asset Catalog

## Agents

| Name | Description |
|------|-------------|
| [my-agent](<repo_url>/blob/main/agents/my-agent.agent.md) | … |
```

## 7. Check Package Exclusions

If the repository contains `scripts/package-basecoat.ps1` or a similar packaging
script, add `mkdocs.yml` to its exclusion list so the build config is not synced
to consumers. If the script cannot be auto-patched, emit a warning:

> ⚠️ Add `mkdocs.yml` to the exclusion list in `<packaging-script>` manually —
> build configuration should not be distributed to consumers.
