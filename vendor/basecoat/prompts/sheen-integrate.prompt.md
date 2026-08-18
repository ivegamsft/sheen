---
description: "Integrate basecoat-sheen into a consumer repository: generate .sheen.yml, run sync, validate, and reset Copilot context. Works in Copilot CLI, VS Code Copilot Chat, and any editor with Copilot Chat support."
model: claude-sonnet-4.6
tools: ["codebase", "githubRepo", "changes", "web"]
---

# Integrate basecoat-sheen

**How to invoke:**

```text
@sheen integrate basecoat-sheen into <YOUR-ORG>/<YOUR-REPO>
```

Or, from inside the target repo:

```text
@sheen integrate basecoat-sheen
```

---

## What This Prompt Does

Drives the full first-time integration of basecoat-sheen into a consumer
repository — from zero to a validated, committed sync with Copilot context
loaded and all skills visible in the `/` picker.

---

## Workflow

### Phase 1 — Discover

Inspect the target repo before generating anything:

1. **Existing customizations** — check `.github/copilot-instructions.md`,
   `.github/agents/`, `.github/skills/`, `.github/instructions/`, `.github/prompts/`.
   Note what exists and whether sheen is already installed (look for `.sheen/manifest.json`).
2. **OS / shell** — detect Windows (PowerShell) vs macOS/Linux (Bash) from the
   environment or user context; this determines which sync script to run.
3. **Team size** — infer from `CODEOWNERS`, `CONTRIBUTING.md`, branch protection.
   Solo → minimal allow-list; Team → cross-functional set; Org → full set.

Produce a one-paragraph **Repo Profile** before proceeding.

---

### Phase 2 — Generate `.sheen.yml`

Draft a `.sheen.yml` tailored to the repo:

```yaml
# .sheen.yml — basecoat-sheen consumer configuration. Commit this file.
source: https://github.com/IBuySpy-Shared/basecoat-sheen.git
ref: v0.7.0          # pin to a release tag for stability

sync:
  # List only the asset names you want (without file suffix).
  # Empty list [] = sync none for that type. Omit key = sync all.
  skills:
    - design-tokens
    - color-system
    - typography
    - accessibility-audit
    - design-review
    # Add more from: https://ivegamsft.github.io/sheen/skills/
  agents:
    - design-system-architect
    - accessibility-auditor
    - brand-steward
    # Add more from: https://ivegamsft.github.io/sheen/agents/
  instructions:
    - sheen-10-design-philosophy
    - sheen-30-token-architecture
    - sheen-50-component-spec
    - sheen-70-accessibility
    - sheen-90-standards-conformance
  prompts: []          # [] syncs none; omit to sync all
  tokens: []           # [] syncs none; omit to sync all
  themes: [light, dark, high-contrast]
  exclude: []

# Uncomment to build CSS/JS output after every sync:
# materialize_tokens: true
```

Adjust `skills`, `agents`, and `instructions` based on the team size signal.
Name values must match the upstream base-name **without** type suffix
(e.g. `design-tokens` not `design-tokens.md`; `accessibility-auditor` not
`accessibility-auditor.agent.md`).

Explain each inclusion briefly.

---

### Phase 3 — Run sync

Print the exact commands for the detected OS:

**Windows (PowerShell):**
```powershell
pwsh -NonInteractive -File sync.ps1
```

**macOS / Linux (Bash):**
```bash
bash sync.sh
```

After the user runs sync, check for success:

1. `.sheen/manifest.json` exists and lists installed files
2. `.github/skills/<name>/SKILL.md` present for each configured skill
3. No `WARNING: allow-list entry … did not match` lines (if any, fix `.sheen.yml` and re-run)

---

### Phase 4 — Validate

```powershell
pwsh -NonInteractive -File scripts/diagnose-sheen.ps1
```

Diagnose must report `sheen: OK` on all checks. Investigate and resolve
any `ERROR` before proceeding.

---

### Phase 5 — Commit

```bash
git add .sheen.yml .sheen/manifest.json .github/ sheen/
git commit -m "chore: integrate basecoat-sheen v0.7.0"
git push
```

---

### Phase 6 — Reset Copilot context ⚠️

> **Critical:** Copilot does not hot-reload skills or agents. After syncing
> `.github/skills/` and `.github/agents/`, the new capabilities are **invisible**
> until the session or window is reset.

Provide the exact reset steps for the user's client:

**Copilot CLI:**
```bash
exit        # end current session
gh copilot  # new session — skills reload from .github/ automatically
```

**VS Code Copilot Chat:**
1. Command Palette (`Ctrl/Cmd + Shift + P`) → **Developer: Reload Window**
2. Open a new chat
3. Type `/` — confirm the synced skills appear in the picker

**JetBrains / other editors:**
Restart the editor to force a Copilot context refresh.

**Verify the reset worked:**
```text
/sheen What skills are available?
```
The router should list the skills that were just synced.

---

### Phase 7 — Summary report

Return a structured integration summary:

```
SHEEN INTEGRATION COMPLETE
─────────────────────────────────────────────────────
Repo:            <owner/repo>
Version synced:  v0.7.0
Skills:          N installed  (e.g. design-tokens, color-system, …)
Agents:          N installed  (e.g. design-system-architect, …)
Instructions:    N installed  (e.g. sheen-10-design-philosophy, …)
Tokens:          <synced / not synced>
Themes:          light ✅ | dark ✅ | high-contrast ✅
Diagnose:        ✅ 0 errors
Context reset:   ✅ (see instructions above)
─────────────────────────────────────────────────────
Next step → Phase 2 (Onboard): run /sheen onboard to configure CI gates.
```

---

## Tips

- If the target is a GitHub URL, use the `githubRepo` tool to inspect it without cloning.
- If running inside the target repo, use `codebase` to read files directly.
- Never write to the repo without explicit user approval.
- If sync warns about unmatched allow-list entries, show the user which names to correct.
- The public asset catalog is at `https://ivegamsft.github.io/sheen/`.
