# Consumption Patterns

Real-world consumption patterns with config recipes and integration touch-points so teams can pick a proven adoption path.

## Quick decision tree

**Pick your pattern:**

1. **Solo designer, small project?** → [Solo-Design](../patterns/solo-design.md)
2. **Design + engineering team, shared repo?** → [Cross-Functional](../patterns/cross-functional.md)
3. **Enterprise org, multiple teams?** → [Cross-Org](../patterns/cross-org.md)
4. **Pure governance, no AI agents needed?** → [Token-Only](../patterns/token-only.md)
5. **Upgrading v0.3 → v0.5?** → [Migration](../patterns/migration.md)

---

## Pattern overview

<div class="grid cards" markdown>

-   **Solo-Design**

    Individual designer, quick iterations. Use case: portfolio, client projects. Focus: design review + accessibility.

    [Deep dive](../patterns/solo-design.md)

-   **Cross-Functional**

    Shared repo, design + eng. Use case: design system, monorepo. Focus: unified tokens + governance.

    [Deep dive](../patterns/cross-functional.md)

-   **Cross-Org**

    Enterprise monorepo, multiple teams. Use case: product suite, platform orgs. Focus: org-wide governance.

    [Deep dive](../patterns/cross-org.md)

-   **Token-Only**

    Pure design system, no AI. Use case: compliance, governance teams. Focus: portable, reusable tokens.

    [Deep dive](../patterns/token-only.md)

-   **Migration**

    Upgrade from v0.3 → v0.5. Use case: existing sheen users. Focus: breaking changes + rollback.

    [Deep dive](../patterns/migration.md)

</div>

---

## Comparison matrix

| Pattern | Duration | Team size | Setup effort | AI agents | Tokens | Success metric |
|---------|----------|-----------|--------------|-----------|--------|-----------------|
| **Solo-Design** | weeks–months | 1 | ✅ Minimal | Optional | No | Design review time ↓20% |
| **Cross-Functional** | ongoing | 2+ | ✅ Low | Recommended | ✅ Yes | Token consistency 95%+ |
| **Cross-Org** | strategic | 10+ | 🟡 Moderate | Recommended | ✅ Yes | Org adoption 80%+ |
| **Token-Only** | ongoing | variable | ✅ Low | No | ✅ Yes | Token coverage 100% |
| **Migration** | 1–2 weeks | N/A | 🟡 Moderate | N/A | Varies | Rollback zero data loss |

---

## Workflow overview

Each pattern has:

- **Profile:** Best-fit team size, timeline, and context
- **.sheen.yml template:** Ready-to-use config with comments
- **Workflow:** Step-by-step integration with your repo
- **Integration points:** How sheen connects to Figma, CSS, CI/CD, etc.
- **FAQ:** Practical questions teams ask
- **Success metrics:** How to measure outcomes

---

## Common FAQ

**Q: Can I start with Solo-Design and grow to Cross-Functional?**

A: Yes, it's a natural progression. Update `.sheen.yml`, re-run `sync.*`, and you're ready. Existing tokens and skills carry forward.

**Q: Do I have to use AI agents?**

A: No. Token-Only pattern excludes agents entirely. Lean and Cross-Functional patterns can too.

**Q: What if my team needs a custom skill?**

A: Fork the repo at team level, add your skill, and link to an issue in basecoat-sheen. This becomes a signal for upstream inclusion.

**Q: How often should we re-sync?**

A: For `ref: main`, monthly is reasonable. For pinned releases (`ref: v0.5.0`), sync only for upgrades. Set a calendar reminder.

**Q: Can we bypass version pinning?**

A: Yes, but not recommended for production. Pinning reduces breaking-change surface and audit risk. See the Migration pattern for upgrade guidance.

**Q: Do tokens have to be in the same repo?**

A: No. You can consume tokens from a separate design-system repo and sheen skills from the product repo. See Cross-Org pattern for federated setups.

**Q: How do we handle breaking token changes?**

A: Follow semver (major.minor.patch based on token schema impact). Document breaking changes in CHANGELOG.md and provide a migration guide. See Migration pattern.

**Q: What's the audit trail for governance?**

A: The sync manifest (`.sheen.manifest.json`) records what was synced, when, and from which ref. Keep it in git. CI diagnostics add observability.

---

## Next steps

Pick the pattern that fits your team and use-case, then:

1. Read the deep-dive (500–800 words, 10 min read)
2. Copy the `.sheen.yml` template and customize
3. Run `sync.ps1` or `sync.sh`
4. Validate with `diagnose-sheen.ps1` (new in v0.5+)
5. Test one workflow before scaling to the team

---

## See also

- [Quick-Start](../getting-started/quick-start.md) — Get running in 10 minutes
- [.sheen.yml Guide](sheen-yml.md) — Reference for all config keys
- [Token Build & CI Integration](token-build-ci.md) — Validate tokens in your pipeline
- [Skill / Agent / Instruction Usage](asset-usage.md) — How to invoke assets in Copilot
