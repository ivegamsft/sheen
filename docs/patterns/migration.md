# Pattern 5: Migration

Upgrade from v0.3 → v0.5, handling breaking changes, rollback strategy.

## Profile

**Best fit:**
- Teams running v0.3 (older version)
- Upgrading to v0.5 (new release)
- Minimal downtime + rollback safety

**Scope:** breaking changes, data migration, rollback plan

**Duration:** 1–2 weeks per team

---

## Breaking changes in v0.5

### 1. Token schema: new composite types

**v0.3:** No composite types (simple values only)

**v0.5:** Added `material` composite type for elevation + shadow

```json
// v0.5 — new type, backward-compatible
{
  "elevation": {
    "z-10": {
      "$type": "material",
      "$value": {
        "shadow": "{shadows.md}",
        "background": "{color.surface}"
      }
    }
  }
}
```

**Impact:** Existing tokens unaffected. New tokens optional. No data loss.

### 2. Instruction naming: formalized prefixes

**v0.3:** Mixed naming (`design-principles.md`, `token-guide.md`)

**v0.5:** All prefixed `sheen-NN-<layer>-<topic>`

```
sheen-10-core-design-principles
sheen-20-tokens-naming
sheen-30-components-states
...
sheen-90-standards-conformance
```

**Impact:** Custom instructions not renamed. sheen-provided instructions follow new naming. No conflicts.

### 3. Skill eval.yaml: improved routing

**v0.3:** Loose routing rules

**v0.5:** More specific eval rules (better skill matching)

**Impact:** Some skill invocations may be routed differently. Test in staging.

### 4. Sync manifest format

**v0.3:** Minimal `.sheen.manifest.json` (what was synced)

**v0.5:** Enhanced with diagnostic fields (versions, checks, etc.)

**Impact:** Backward-compatible. Old manifests still valid, new ones have more data.

---

## Pre-flight checklist

- [ ] **Backup:** Commit current `.sheen.yml` and sync manifest to git
- [ ] **Review breaking changes:** Read this guide
- [ ] **Test in staging:** Clone repo, test migration locally
- [ ] **Document custom assets:** List any custom skills/instructions
- [ ] **Notify team:** Announce 1-day migration window
- [ ] **Schedule rollback:** Have 30 min free for rollback if needed

---

## Migration steps

### Step 1: Backup current state

```bash
git status  # ensure clean working tree
git log --oneline -1  # note current commit
# .sheen.yml and .sheen.manifest.json are already in git
```

### Step 2: Update .sheen.yml

Change `ref: main` (or tag) to `ref: v0.5.0`:

```yaml
source: https://github.com/IBuySpy-Shared/basecoat-sheen.git
ref: v0.5.0  # changed from main or v0.3.x
```

Or upgrade step-by-step (v0.3 → v0.4 → v0.5):

```yaml
ref: v0.4.5  # intermediate version
```

### Step 3: Run sync

```bash
./sync.ps1  # PowerShell (Windows)
# or
./sync.sh   # Bash (Unix)
```

Output will show:
- Downloaded assets
- Synced files
- New manifest written

### Step 4: Validate

```bash
# New in v0.5: diagnostic tool
./scripts/diagnose-sheen.ps1 --validate-all

# Or quick check (token schema):
./scripts/diagnose-sheen.ps1 --validate-tokens
```

Expected output: `✅ All checks passed` or specific errors.

### Step 5: Test workflows

Run one skill from each category:

```bash
# Invoke via Copilot CLI or chat:
# "design-review: review this component layout"
# "token-audit: check my color palette"
# "accessibility-audit: WCAG check"
```

### Step 6: Merge PR

1. Create branch: `git checkout -b upgrade/v0.5.0`
2. Commit: `git add .sheen.yml .sheen.manifest.json && git commit -m "Upgrade: basecoat-sheen v0.3 → v0.5.0"`
3. Push: `git push origin upgrade/v0.5.0`
4. PR: Request review from design + eng leads
5. Merge: Once CI passes and team confirms tests work

### Step 7: Monitor

After merge:
- Run diagnostics in CI: `diagnose-sheen.ps1` (add to GitHub Actions)
- Team validates: 1–2 workflows per person (skill invocations)
- No issues? Celebration 🎉
- Issues? See rollback section below

---

## Rollback plan

If something breaks:

```bash
# Revert to previous version
git revert HEAD --no-edit  # creates new commit
git push origin main

# Re-sync from old version
./sync.ps1  # syncs from previous ref in reverted .sheen.yml

# CI will re-run diagnostics with old version
```

**Expected outcome:** Back to pre-upgrade state, no data loss.

**Time to rollback:** <5 minutes

**Testing after rollback:** Run same workflows to confirm restoration

---

## FAQ

**Q: Can I run v0.3 and v0.5 in parallel?**

A: No. Only one version per repo (sync is exclusive). Choose: upgrade or stay on v0.3.

**Q: Will my existing tokens break?**

A: No. Core tokens (palette, type scale, spacing) are backward-compatible. New composite types are opt-in.

**Q: What if I customized a skill in v0.3?**

A: Merge custom changes with v0.5 skill code. Most likely no conflicts (skills rarely change). Test thoroughly.

**Q: Data loss risk?**

A: None. Sync is idempotent. All changes tracked in git. Rollback is a git revert + re-sync.

**Q: How long does migration take?**

A: 30 min per team (backup, sync, test, commit). Larger orgs: 2–3 weeks rolling out.

**Q: Do I have to upgrade?**

A: No. v0.3 will continue to work. But v0.5 has improvements (better routing, validation tool). Recommend upgrading within quarter.

**Q: What if CI breaks after merge?**

A: Likely new CI checks (v0.5 adds `diagnose-sheen.ps1`). Fix by addressing diagnostic errors or temporarily disabling new checks (then fix properly).

**Q: How to upgrade incrementally?**

A: Use intermediate release tag (e.g., v0.3 → v0.4 → v0.5). Follow same migration steps per version.

---

## Version support policy

- **Current:** v0.5.x (full support)
- **Previous:** v0.4.x (bug fixes only, 6 months)
- **Older:** v0.3.x (EOL, no support)

**Upgrade window:** 30 days from release. After that, teams on older versions are unsupported.

---

## Org-wide rollout (multiple teams)

1. **Pilot team:** Upgrade first, document learnings
2. **Design review board:** Approve rollout plan (30-day window)
3. **Team stagger:** Upgrade 2–3 teams per week
4. **Central comms:** Announce milestones (50%, 75%, 100% adoption)
5. **EOL notice:** After 30 days, stop supporting v0.3

---

## Testing checklist

After migration, test these workflows:

- [ ] Design review skill: invoke with sample component
- [ ] Token audit skill: run on `.tokens.json`
- [ ] Accessibility audit: check WCAG compliance
- [ ] CI gate: ensure diagnostics pass in pipeline
- [ ] Figma sync: if using tokens, verify sync works
- [ ] Component library: ensure CSS/Tailwind tokens load
- [ ] Documentation: check that docs render correctly

All passing? Migration successful!

---

## Success metrics

- **Migration time:** <2 hours per team
- **Zero data loss:** All previous configs preserved
- **All teams on v0.5:** Within 30 days
- **Zero rollbacks:** Successful first-try migrations

---

## See also

- [Cross-Org Pattern](cross-org.md) — Enterprise upgrade coordination
- [.sheen.yml Guide](../guides/sheen-yml.md) — Config reference
