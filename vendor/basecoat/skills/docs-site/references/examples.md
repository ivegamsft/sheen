# Docs Site — Examples and Anti-Patterns

## Examples

### Python Library

```yaml
site_name: "Mylib"
site_url: "https://myorg.github.io/mylib/"
repo_url: "https://github.com/myorg/mylib"
docs_structure: "docs/ contains index.md, api/, and CHANGELOG.md; src/ is the package root"
install_pattern: "pip install mylib"
theme_color: "teal"
nav_style: "sidebar"
```

Generates a sidebar-nav site with pip install tab and a `docs/reference/` API
section derived from the `api/` folder.

### BaseCoat-Style Agent Repository

```yaml
site_name: "BaseCoat"
site_url: "https://myorg.github.io/basecoat/"
repo_url: "https://github.com/myorg/basecoat"
docs_structure: "agents/, skills/, instructions/, prompts/ at root; docs/ has overview.md"
install_pattern: "pwsh scripts/sync-basecoat.ps1 -Repo myorg/basecoat"
asset_types: "agents, skills, instructions"
theme_color: "indigo"
nav_style: "tabs"
exclude_from_package: "mkdocs.yml"
```

Generates a tabbed site, a PowerShell-first getting-started guide, an asset
catalog for agents/skills/instructions, and patches `scripts/package-basecoat.ps1`
to exclude `mkdocs.yml`.

## Anti-Patterns

- Do not generate domain-specific C4 diagrams — keep diagrams generic so the
  caller can customize them without regenerating the whole scaffold.
- Do not hardcode org or repo names in generated files — derive everything from
  `repo_url` and other inputs only.
- Do not use relative markdown links in the asset catalog — always use absolute
  GitHub URLs so links remain valid regardless of where the page is served from.
- Do not sync `mkdocs.yml` to consumers — it is a build configuration file, not
  guidance content. Always add it to the package exclusion list.
- Do not use PowerShell `Set-Content` for file writes — it introduces CRLF line
  endings that corrupt MkDocs YAML parsing. Use `Out-File -Encoding utf8` or
  redirect operators instead.
