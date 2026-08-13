# Orphaned PR Triage Checklist

1. Query open PRs and sort by last activity date.
2. Exclude protected labels (`do-not-close`, `release-blocker`).
3. Classify each candidate:
   - **Revive**: still relevant, missing reviewer/owner
   - **Close**: superseded, obsolete, or stale beyond policy
   - **Escalate**: blocked by merge conflicts or dependency decisions
4. Post a standard comment and assign owner/date.
5. Publish weekly metrics:
   - stale PR count
   - median PR age
   - revived vs closed ratio
