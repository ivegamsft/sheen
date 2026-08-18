---
description: "Upgrade basecoat-sheen in a consumer repository to a new version: review changelog, run sync, validate, and reset Copilot context so updated skills and agents load. Works in Copilot CLI, VS Code Copilot Chat, and any editor with Copilot Chat support."
model: claude-sonnet-4.6
tools: ["codebase", "githubRepo", "changes", "web"]
---

# Upgrade basecoat-sheen

**How to invoke:**

```text
@sheen upgrade basecoat-sheen to v<NEW-VERSION>
```

Or, specifying source and target:

```text
@sheen upgrade basecoat-sheen from v<OLD> to v<NEW>
```

---

## What This Prompt Does

Drives a safe, validated upgrade of an existing basecoat-sheen consumer
installation — changelog review, sync, allow-list reconciliation, validation,
commit, and Copilot context reset.

---

## Workflow

### Phase 1 — Discover current state

Read the current installation:

1. **Installed version** — read `.sheen/manifest.json` → `ref` field.
   If missing, treat as unmanaged (recommend Phase 1 integrate first).
2. **Allow-list config** — read `.sheen.yml` → `sync` block.
3. **Installed assets** — list `.github/skills/`, `.github/agents/`, `.github/instructions/`.
4. **OS / shell** — detect Windows vs macOS/Linux.

Report a one-line **Current State** before proceeding:
```
Current: v0.6.x | 12 skills | 4 agents | 5 instructions | Windows
```

---

### Phase 2 — Review changelog

Fetch and display the relevant CHANGELOG entries:

```bash
curl -fsSL https://raw.githubusercontent.com/IBuySpy-Shared/basecoat-sheen/<TARGET>/CHANGELOG.md
```

Extract and show only entries between `[<CURRENT>]` and `[<TARGET>]`.

**Look for and call out explicitly:**
- Any `### Breaking` sections
- Renamed skills or agents (the old name will produce an allow-list warning after sync)
- Removed assets (they will be pruned from `.github/` on re-sync)
- New assets available (user may want to add them to `.sheen.yml`)

Ask the user to confirm they want to proceed before running sync.

---

### Phase 3 — Update `.sheen.yml`

```yaml
ref: v<NEW-VERSION>   # was: v<OLD-VERSION>
```

If changelog revealed renames, update allow-list entries to the new names now.

---

### Phase 4 — Run sync

**Windows (PowerShell):**
```powershell
pwsh -NonInteractive -File sync.ps1
```

**macOS / Linux (Bash):**
```bash
bash sync.sh
```

Capture and report all output. Flag any:

- `WARNING: allow-list entry … did not match` — upstream rename or removal.
  Show the user the old name and suggest the new name from the changelog.
- Files removed during post-pass pruning (asset renamed or removed upstream).
- New files written (new assets added at the target ref).

If there are unresolved `WARNING` lines after the user updates `.sheen.yml`,
re-run sync until no warnings remain.

---

### Phase 5 — Validate

```powershell
pwsh -NonInteractive -File scripts/diagnose-sheen.ps1
```

All checks must pass (`sheen: OK`). Investigate and fix any `ERROR` before
proceeding. Common causes:

| Error | Fix |
|-------|-----|
| Token alias not found | Upstream token was renamed; re-sync at new ref |
| Agent description missing USE FOR | Agent file was replaced; check `.github/agents/` |
| Manifest commit mismatch | Run sync again; commit was not captured correctly |

---

### Phase 6 — Commit

```bash
git add .sheen.yml .sheen/manifest.json .github/ sheen/
git commit -m "chore: upgrade basecoat-sheen to v<NEW-VERSION>"
git push
```

---

### Phase 7 — Reset Copilot context ⚠️

> **Critical:** Updated skills and agents are **invisible** to Copilot until
> the session is reset. Do not skip this step.

Provide the exact reset steps:

**Copilot CLI:**
```bash
exit        # end current session
gh copilot  # new session — updated skills reload from .github/ automatically
```

**VS Code Copilot Chat:**
1. Command Palette (`Ctrl/Cmd + Shift + P`) → **Developer: Reload Window**
2. Open a new chat
3. Type `/` — verify updated skill descriptions appear (not the old ones)

**JetBrains / other editors:**
Restart the editor to force a Copilot context refresh.

**Verify the upgrade loaded:**
```text
/sheen What version am I on?
```
The router reads `.sheen/manifest.json` and should report the new version.

---

### Phase 8 — Summary report

```
SHEEN UPGRADE COMPLETE
─────────────────────────────────────────────────────
Repo:            <owner/repo>
From:            v<OLD-VERSION>
To:              v<NEW-VERSION>
─────────────────────────────────────────────────────
Assets updated:  N files changed
Assets added:    N new (e.g. <name>, <name>)
Assets removed:  N pruned (e.g. <name> — renamed upstream)
Allow-list fixes: N entries updated in .sheen.yml
Diagnose:        ✅ 0 errors
Context reset:   ✅ (see instructions above)
─────────────────────────────────────────────────────
Breaking changes applied:
  - <list any breaking changes from changelog>
Recommended next steps:
  1. Verify skills work end-to-end: /sheen <skill-keyword> <test request>
  2. Update any custom overrides in .github/skills/ that may have been
     replaced by the upstream sync.
```

---

## Tips

- Always review the changelog before upgrading in a production consumer repo.
- Pin `ref` to a release tag (e.g. `v0.7.0`) — never use `ref: main` in production.
- If an allow-list entry warns after upgrade, check the [release notes](https://ivegamsft.github.io/sheen/changelog/) for renamed assets.
- The automated upgrade script (`scripts/upgrade-sheen.ps1` / `scripts/upgrade-sheen.sh`) can run all phases non-interactively for CI pipelines. See `docs/guides/upgrading-sheen.md`.
- Never overwrite consumer-customized files in `.github/skills/` without asking first.
