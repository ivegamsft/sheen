# Architecture Decision Record Template

Use this template to record significant architecture decisions. One ADR per decision. Never delete an ADR — supersede it with a new one that links back to the original.

---

## ADR-{NUMBER}: {Title}

**Date:** {YYYY-MM-DD}

**Status:** {Proposed | Accepted | Superseded | Deprecated}

**Supersedes:** {ADR-NNN (if applicable, otherwise remove this line)}

**Superseded by:** {ADR-NNN (if applicable, otherwise remove this line)}

---

### Context

{Describe the situation and the forces at play. What problem are you trying to solve? What constraints exist? What quality attributes matter most? Include enough background that a reader unfamiliar with the project can understand why a decision was needed.}

### Decision

{State the decision clearly and concisely. Use active voice: "We will use…", "The system will…", "Teams must…". Be specific about what was chosen and what was explicitly rejected.}

### Consequences

#### Positive

- {Benefit 1}
- {Benefit 2}

#### Negative

- {Trade-off or cost 1}
- {Trade-off or cost 2}

#### Risks

- {Risk introduced by this decision and planned mitigation}

---

## Governance Rules

- A decision is significant if it is hard to reverse, affects multiple teams or services, or commits the project to a technology or pattern for more than one sprint.
- ADRs must be reviewed by at least one other team member before moving from `Proposed` to `Accepted`.
- When a decision is reversed, create a new ADR with status `Accepted` and update the original ADR's status to `Superseded` with a link to the new ADR.
- Store ADRs in version control alongside the code they govern (e.g., `docs/adr/` or `architecture/decisions/`).
