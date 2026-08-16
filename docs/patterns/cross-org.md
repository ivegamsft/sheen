# Pattern 3: Cross-Org

Enterprise monorepo, multiple product teams, shared design governance, org-wide policy.

## Profile

**Best fit:**
- Large product suite with multiple teams
- Shared design system maintained by platform team
- Org-wide governance without centralizing all work
- Need audit trails and compliance tracking

**Duration:** ongoing (strategic)

**Team size:** 10+ developers, 5+ designers, dedicated platform team

**Why this pattern:**
- Org-wide governance without siloing teams
- Each team picks assets relevant to their product
- Central version pinning ensures stability
- Compliance + audit trails built-in
- Easy to track adoption and measure impact

---

## .sheen.yml config

### Central platform team template

```yaml
# Cross-Org Mode — org-wide reference, maintained by platform team
source: https://github.com/IBuySpy-Shared/basecoat-sheen.git  # or internal mirror
ref: v0.5.0  # pin to release tag for production stability

# Platform team: all assets (full reference)
skills: []
agents: []
instructions: []
themes: [light, dark, high-contrast]

# Optional: diagnostic reporting
sync:
  exclude:
    - archive/   # skip deprecated assets
```

### Product team A (design-heavy) template

```yaml
# Cross-Org Mode — product team variant (design-focused)
source: https://github.com/IBuySpy-Shared/basecoat-sheen.git
ref: v0.5.0  # sync from central platform team version

# Design-focused skills only
skills:
  - design-review
  - design-system-audit
  - accessibility-audit
  - web-usability-review

# All instructions (ambient governance)
instructions: []

# Include themes if using token-driven CSS
themes: [light, dark]
```

### Product team B (eng-heavy) template

```yaml
# Cross-Org Mode — product team variant (implementation-focused)
source: https://github.com/IBuySpy-Shared/basecoat-sheen.git
ref: v0.5.0

# Implementation-focused skills
skills:
  - token-audit
  - design-system-audit

# All instructions
instructions: []

themes: [light, dark]
```

---

## Workflow

### Phase 1: Central governance setup

1. **Platform team** maintains `.sheen.yml` templates for each team type
2. **CI/CD:** Central pipeline runs `diagnose-sheen.ps1` on all sync events
3. **Version pin:** Org-wide policy uses single `ref` tag (e.g., v0.5.0)
4. **Audit trail:** Sync manifests archived in central repo for compliance

### Phase 2: Team onboarding

5. **New team** copies template for their role (design, eng, platform)
6. **Customize:** Edit skills/themes list based on product needs
7. **First sync:** `sync.ps1`, validate with `diagnose-sheen.ps1`
8. **CI gate:** Add diagnostic checks to team's GitHub Actions

### Phase 3: Upgrade cycles

9. **Quarterly:** Platform team evaluates new sheen release
10. **Test:** Validate in staging (CI gates, team workflows)
11. **Release candidate:** Publish upgrade guide with breaking changes
12. **Rollout:** Teams upgrade within 30-day window (enforced via CI gates)

### Phase 4: Ongoing governance

13. **Design review board:** Quarterly meetings (major decisions, token versioning)
14. **Sync events:** Logged and audited (who synced, when, from which version)
15. **Issue reporting:** Teams link issues to decisions (PR + token changes)

---

## Integration points

### Internal mirror (optional)

For air-gapped environments:

```bash
# Central team mirrors upstream weekly
git mirror https://github.com/IBuySpy-Shared/basecoat-sheen.git \
  https://git.internal.company/mirrors/basecoat-sheen.git
```

Update team configs to use internal mirror:
```yaml
source: https://git.internal.company/mirrors/basecoat-sheen.git
ref: v0.5.0
```

### CI/CD governance

**GitHub Actions — central org-wide gate:**

```yaml
- name: Validate sheen sync
  run: ./scripts/diagnose-sheen.ps1 --validate-all
  
- name: Archive sync manifest
  if: success()
  run: |
    cp .sheen.manifest.json \
      gs://compliance-audit/sheen/${{ github.repo }}/${{ github.ref }}/${{ github.sha }}.json
```

### Audit logs

- Sync manifest stored in `compliance-audit/` bucket
- Diagnostic reports captured (which skills, which versions, which errors)
- Query for: "which teams synced in last quarter?" or "when was v0.5.0 adopted?"

### Compliance + reporting

- **Policy:** Track token usage, design principle adherence
- **Analytics:** Observability dashboard (future Wave 3+)
  - Adoption by team
  - Skill usage heatmap
  - Version lag tracking

---

## Governance structure

### Central (Platform Team)

- Owns `.sheen.yml` templates and upgrade guides
- Maintains internal mirror (if air-gapped)
- Runs quarterly design review board
- Publishes release calendar and breaking-change notices

### Distributed (Product Teams)

- Use templates, customize for product
- Run `diagnose-sheen.ps1` in team CI
- Propose custom skills as GitHub issues
- Report adoption blockers to platform team

### Design Review Board (Quarterly)

- Attendees: 2–3 platform leads, 1–2 design chairs, 1–2 eng leads
- Decisions: token versioning, major instruction changes, org-wide policy
- Outcomes: documented in ADR (architecture decision record)
- Links: ADRs reference token changes, released in CHANGELOG.md

---

## FAQ

**Q: How do teams stay in sync?**

A: Central version pinning (`ref: v0.5.0`). Quarterly upgrade cycles with 30-day rollout window. CI gates enforce compliance.

**Q: What if a team needs a custom skill?**

A: Fork at team level, add skill, link to issue in basecoat-sheen. This becomes signal for upstream inclusion. Share in next design review board.

**Q: Breaking changes — what's the rollback strategy?**

A: Keep 2 minor versions supported (e.g., v0.4 and v0.5). Upgrade within 30 days enforced by CI. Rollback: `git revert` + re-sync.

**Q: How do we audit token usage?**

A: `diagnose-sheen.ps1` + observability (future). Track: which team uses which tokens, token change frequency, principle adherence.

**Q: What if teams want different token values?**

A: Use semantic tokens at org level (e.g., `color.primary`), let teams override at product level (e.g., `product-a.color.primary`). Document in token ADR.

**Q: Can we disable sheen for a team?**

A: Yes, but not recommended. Instead, minimal config with only `instructions: []` (pure ambient guidance). Flag in compliance audit.

**Q: How to measure adoption?**

A: Sync manifest telemetry: teams adopting, version lag, skill usage. Design review board reviews quarterly.

---

## Success metrics

- **Org adoption:** 80%+ teams using sheen within 6 months
- **Breaking change adoption time:** <30 days org-wide (enforced by policy)
- **Design consistency score:** 90%+ (tokens + principles)
- **Audit coverage:** 100% (all sync events logged)
- **Skill usage:** >5 skills per team on average (adoption signal)

---

## Next steps

1. Platform team publishes `.sheen.yml` templates in shared repo
2. Announce upgrade schedule (quarterly, 30-day rollout)
3. Product teams onboard incrementally (start with design-heavy, then eng-heavy)
4. Run first org-wide diagnostics: `diagnose-sheen.ps1 --org-report`
5. Design review board meets quarterly to review adoption and policy

---

## Transition paths

- **From Cross-Functional:** Add more teams, set up central governance templates
- **To Token-Only:** Reduce scope to tokens only (many orgs start here for compliance)
