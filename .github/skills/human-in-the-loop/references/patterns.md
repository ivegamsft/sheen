# Human-in-the-Loop Patterns

## Confirmation Gate Pattern

Before executing a gated action:

- Present a concise plan summary
- Describe the expected impact
- Include a rollback strategy
- Wait for explicit approval instead of auto-proceeding on timeout
- Log the human's decision for an audit trail
- If no human is available, queue the action rather than skipping it silently

## Escalation Triggers

Escalate when any of the following occurs:

- Error count exceeds threshold (3+ failures on the same task)
- Token budget is approaching its limit while work remains incomplete
- Conflicting requirements are detected
- A security-sensitive file modification is detected
- A test suite regression is introduced

## Approval Workflows

### Synchronous

The agent pauses, asks the user for approval, and waits for a response before continuing the gated step.

### Asynchronous

The agent creates a PR or issue for review, continues other independent work, and checks back later for a decision.

### Delegated

The agent asks a more capable agent to review or validate the approach, then falls back to a human if that delegation fails.

## Graceful Degradation

When human input is unavailable:

- Document what is blocked and why
- Complete what can be done without approval
- Create a clear handoff for when the human returns
- Never silently skip a confirmation gate
- Set a timeout with an explicit `action deferred` status

## Anti-Patterns

- Auto-approving after timeout because it defeats the purpose of the gate
- Asking for confirmation on every trivial action, which creates approval fatigue
- Asking for binary yes/no decisions without context, which prevents informed judgment
- Blocking all work when one step needs approval instead of parallelizing the rest
