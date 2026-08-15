# Sync Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| Missing assets | Allow-list too narrow | Widen `.sheen.yml`, then re-sync |
| Conflicts | Local file changes in the consumer repo | Resolve conflicts first, then sync |
| Wrong source | Bad `source` or `ref` | Recheck the config and pin a valid ref |
| Token failures | Theme or reference drift | Run token validation and fix the source tokens |

## Fast rule

If the expected asset family is missing, inspect `.sheen.yml` before you inspect
the sync tool.
