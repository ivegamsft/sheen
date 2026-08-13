---
description: "Use when planning a shared standards repository with auto-sync capabilities for GitHub Copilot customizations across teams."
---

# Base Coat — Shared Standards Repository with Auto-Sync

## Plan Overview
Create a central `.github/base-coat/` repository with shared Copilot customizations (instructions, skills, prompts, agents) organized by type. Teams pull updates on demand using a lightweight sync script.

## Repository Structure
```
base-coat/
├── README.md                    # Setup guide for teams
├── sync.sh (or sync.ps1)       # Script teams run to pull latest
├── version.json                 # Track releases/changelog
├── instructions/
│   ├── README.md               # What each instruction does
│   ├── backend.instructions.md
│   ├── frontend.instructions.md
│   └── testing.instructions.md
├── skills/
│   ├── performance-profiling/
│   │   ├── SKILL.md
│   │   ├── templates/
│   │   └── examples/
│   └── code-review/
│       ├── SKILL.md
│       └── ...
├── prompts/
│   ├── architect.prompt.md
│   └── code-review.prompt.md
└── agents/
    └── code-review.agent.md
```

## How Teams Consume It

### Option 1: Sync Script (Recommended for continuous updates)
```bash
# Teams run this in their repo to pull latest base-coat standards
curl -s https://raw.githubusercontent.com/your-org/base-coat/main/sync.sh | bash
```
The script copies `.github/base-coat/skills`, `.github/base-coat/instructions`, etc. into their repo.

### Option 2: Git Submodule (Point-in-time reference)
```bash
git submodule add https://github.com/your-org/base-coat.git .github/base-coat
```
Teams pull updates manually: `git submodule update --remote`

### Option 3: Hybrid (Script + Git)
Sync script clones minimal shared standards into `.github/` at team's desired git tag/branch.

## Lightweight Implementation Path

1. **Create the repo** with your current customizations organized by type
2. **Write a sync script** (50-100 lines) that teams can run one-time
3. **Document**: README with discovery guidance and adoption steps
4. **Version it**: Use git tags (v1.0.0, v1.1.0) so teams pin stable releases
5. **Optional**: Add GitHub Actions to validate that all SKILL.md files are syntactically correct before merge

## First Files to Create

| File | Purpose |
|------|---------|
| `README.md` | Installation + discovery instructions |
| `sync.sh` | Copies customizations to team repos |
| `INVENTORY.md` | Catalog: what each skill/instruction does + keywords for discovery |
| `CHANGELOG.md` | What changed in each version |

## Example Sync Script (Lightweight)
```bash
#!/bin/bash
GIT_REPO="https://github.com/YOUR-ORG/base-coat.git"
TARGET_DIR=".github/base-coat"

cd "$(git rev-parse --show-toplevel)" || exit 1
git clone --depth 1 "$GIT_REPO" "$TARGET_DIR" 2>/dev/null || (cd "$TARGET_DIR" && git pull)
echo "✓ Base Coat standards updated to latest version"
```

## Distribution Options Ranked by Ease

| Option | Setup Effort | Upgrade Friction | Best For |
|--------|--------------|------------------|----------|
| **Git submodule** | Medium | Low (auto on pull) | Stable, infrequently changing standards |
| **Sync script** | Low | Very low (on-demand) | Frequently updated standards |
| **Copy-paste + docs** | Minimal | High (manual copy) | Small teams just starting |
| **VS Code Marketplace** | High | Very low | Org-wide extension (future) |

## What Goes in Each Customization Type

- **Instructions**: Coding standards, review guidelines, language-specific best practices
- **Skills**: Reusable workflows (testing, profiling, refactoring patterns)
- **Prompts**: Quick one-off tasks teams can invoke
- **Agents**: Multi-step workflows requiring tool isolation
