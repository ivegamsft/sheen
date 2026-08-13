# Sprint Retrospective Templates & Formulas

## Retrospective Document Template

````markdown
# {Title} — {Date Range}

## Summary

{2-3 sentence executive summary of the period}

## Timeline

| Time | Event | Reference |
|------|-------|-----------|
| {timestamp} | {description} | #{number} / {sha} |

## Metrics

| Metric | Value |
|--------|-------|
| Issues resolved | {count} |
| PRs merged | {count} |
| Avg time-to-merge | {duration} |
| Lines added / removed | +{added} / -{removed} |
| Parallel dispatch ratio | {ratio} |

## What Went Well

- {observation with evidence}

## What To Improve

- {observation with evidence}

## Actionable Tips

1. {specific tip based on observed pattern}
````

## Metrics Formulas

- **Time-to-merge**: `PR merged_at - PR created_at` (exclude draft time if available)
- **Parallel dispatch ratio**: `max concurrent open PRs / total PRs` over the period
- **Velocity**: `issues closed / calendar days` in the period
- **Churn rate**: `lines removed / lines added` — high churn suggests rework

## Tips Taxonomy

| Category | Pattern Signal | Tip Template |
|----------|---------------|--------------|
| Parallelism | Serial PR pattern (one at a time) | "Consider launching independent tasks in parallel — {n} of {total} PRs had no dependency on each other" |
| PR size | PRs with >500 lines changed | "Break large PRs into focused changes — PR #{n} touched {files} files across {dirs} directories" |
| Merge lag | Time-to-merge > 24h | "PRs sat idle for {avg} hours — consider async review or auto-merge for low-risk changes" |
| Rework | Multiple commits fixing same area | "File {path} was modified in {n} separate PRs — consider a more thorough upfront design" |
| Documentation | Code changes without doc updates | "Sprint had {code_prs} code PRs but only {doc_prs} doc updates — keep docs in sync" |

## GitHub API Queries

Use these to gather retrospective data:

- **Commits**: `gh api repos/{owner}/{repo}/commits --jq '.[].sha' -f since={start} -f until={end}`
- **PRs merged**: `gh pr list --state merged --search "merged:>{start}" --json number,title,mergedAt,additions,deletions`
- **Issues closed**: `gh issue list --state closed --search "closed:>{start}" --json number,title,closedAt`
- **Code scanning**: `gh api repos/{owner}/{repo}/code-scanning/alerts --jq '.[].rule.id'`
