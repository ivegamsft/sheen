# Copilot CLI Usage Report Template

This template is used by the Copilot CLI Usage Analytics skill to generate per-session usage and cost reports.

---

## Session Summary

- **Session ID:** {{session_id}}
- **Start Time:** {{start_time}}
- **End Time:** {{end_time}}
- **Total Agent Dispatches:** {{dispatch_count}}
- **Total Tool Calls:** {{tool_call_count}}
- **Estimated Total Tokens:** {{token_estimate}}
- **Estimated Cost:** ${{cost_estimate}}

## Model Usage Breakdown

| Model Name | Dispatches | Estimated Tokens | Estimated Cost |
|--------------------|------------|-----------------|---------------|
<!-- markdownlint-disable MD055 MD056 -->
{{#each model_usage}}
| {{model}} | {{dispatches}} | {{tokens}} | ${{cost}} |
{{/each}}
<!-- markdownlint-enable MD055 MD056 -->

## Recommendations

- {{recommendations}}

## Notes

- Cost and token estimates are based on session-local tracking. For authoritative data, use GitHub Copilot Metrics API when available.
- APIs checked: REST (no per-session), Billing (no usage), Power BI (auth error)
