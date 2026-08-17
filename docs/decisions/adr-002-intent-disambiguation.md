# ADR-002 — Intent Disambiguation Strategy

| Field | Value |
|---|---|
| **Date** | 2026-08-16 |
| **Status** | Accepted |
| **Deciders** | sheen maintainers |
| **Supersedes** | — |
| **Superseded by** | — |

## Context

Once the sheen router (ADR-001) and `sheen.vocab.yaml` vocabulary were in place, a
new class of routing failure emerged: **ambiguous intents** where the same keyword
resolves to different skills depending on context, or where sheen and basecoat share
vocabulary.

Concrete examples that surfaced during design review:

| User input | Candidate A (sheen) | Candidate B (basecoat vendor) |
|---|---|---|
| `debate` | `design-debate` → `@design-reviewer` | CI/CD diagnostics reference |
| `design` | sheen pillar → 6 agents | `@solution-architect` |
| `ship-it` | `ship-it` skill (exact) | `ship-it-control-loop` (prefix) |
| `rca` | `rca` skill (process failure) | `build-failure-triage` (CI failure) |

## Options Considered

### Strategy 1 — Namespace Prefix (strict)
Every cross-domain keyword is prefixed: `/sheen:debate`, `/basecoat:rca`.

- ✅ Zero ambiguity
- ❌ Users must know the namespace before they know which skill they need — defeats
  discoverability for new users.

**Score: 5 / 10**

### Strategy 2 — Clarifying Question (interactive)
On any ambiguous match, the router presents 2–3 candidates and waits for the user to pick.

- ✅ Always correct; self-documenting
- ❌ Adds a round-trip; breaks fleet / autopilot mode where there is no user to answer.

**Score: 7 / 10** — good fallback, poor primary strategy.

### Strategy 3 — Artifact-Type Discriminator + Question Fallback *(chosen)*
The router inspects **the noun following the ambiguous verb** to auto-resolve.
Each ambiguous intent carries a `discriminator` field with `artifact_types` (include)
and `excludes` (cross-domain exclusion). If no noun is present, fall through to
Strategy 2 (clarifying question). In fleet / autopilot mode, pick highest-confidence
match and log the decision.

**Score: 9 / 10**

## Decision Criteria

| Criterion | Weight | S1 | S2 | S3 |
|---|---|---|---|---|
| Autopilot / fleet safety | 35% | 10 | 2 | 9 |
| User discoverability | 25% | 3 | 9 | 9 |
| Implementation simplicity | 20% | 9 | 8 | 7 |
| Cross-domain correctness | 20% | 10 | 8 | 9 |
| **Weighted total** | | **7.9** | **6.1** | **8.7** |

## Decision

**Adopt Strategy 3 — Artifact-Type Discriminator with Question Fallback.**

### Five-Step Resolution Chain

Resolution proceeds in order; the first match that returns a single candidate wins:

```
1. Exact match          → ship-it ≠ ship-it-control-loop (longest-token match wins)
2. Namespace prefix     → sheen: prefix always routes to sheen; basecoat: routes to basecoat
3. Artifact discriminator → noun after verb resolves cross-domain conflict
4. Clarifying question  → interactive mode only; present top 2–3 candidates
5. Fleet / autopilot    → pick highest-confidence match, annotate decision in output
```

### Discriminator Field Schema (in `sheen.vocab.yaml`)

```yaml
- intent: "debate-design-options"
  keywords: ["debate", "tradeoff", "compare", "options"]
  discriminator:
    artifact_types: ["component", "wireframe", "token", "brand", "layout", "flow",
                     "option", "pattern", "style", "theme"]
    excludes:       ["pipeline", "ci", "build", "incident", "outage", "failure", "alert"]
  skill: "design-debate"
  agent: "design-reviewer"
```

### Canonical Disambiguation Table

| Ambiguous keyword | Discriminating nouns → sheen | Discriminating nouns → basecoat | Default |
|---|---|---|---|
| `debate` | component, wireframe, token, brand, flow | pipeline, ci, build | sheen (design domain) |
| `design` | token, theme, brand, layout, component | system, architecture, api, service | sheen |
| `ship-it` | *(exact match; no suffix)* | control, loop, gate | `ship-it` skill |
| `rca` | decision, pattern, design | incident, outage, alert, failure | basecoat (operational) |
| `audit` | design, token, brand, a11y, craft | security, config, infra, cloud | context-dependent → ask |
| `review` | design, component, wireframe, craft | code, pr, pull-request | context-dependent → ask |

### Governance Rules

- `discriminator` is **optional**; omit it for keywords that are unambiguous within
  the sheen domain.
- When adding a new intent that shares a keyword with an existing one (sheen or
  basecoat), a `discriminator` block is **required**.
- Keyword uniqueness within a single router (sheen or basecoat) is still enforced.
  Discriminators only resolve *cross-router* and *cross-intent* conflicts.
- Fleet/autopilot confidence threshold: if the discriminator match score is < 0.7
  (i.e., noun is present but weakly matches both `artifact_types` and `excludes`),
  log a `[ROUTING NOTE]` in the output and proceed with the higher-score candidate.

## Consequences

- **Positive:** Fleet agents never block on a clarifying question for common
  cross-domain terms (`design`, `debate`, `rca`, `ship-it`).
- **Positive:** New skills with ambiguous names get a structured place to declare
  their discriminator — no ad-hoc workarounds.
- **Positive:** The governance table above is the living canonical reference; update
  it here when new conflicts are discovered.
- **Risk:** `discriminator.artifact_types` lists are manually maintained. A noun that
  is not in the list will fall through to the clarifying-question step unnecessarily.
  Mitigated by tracking misses in the `sheen.vocab.yaml` issue (follow-up).
- **Risk:** The five-step chain is documented in prose; it is not yet machine-enforced
  in a CI gate. A future spec (Spec 09 — Router Contract) should codify it.

## Implementation

Delivered in PR #38 addendum (`feat/sheen-router`), merged 2026-08-16.
The `discriminator` field extension to `sheen.vocab.yaml` and `build-metadata.ps1`
is tracked as a follow-up issue (see issue log).

Related: [ADR-001 — Sheen Router](adr-001-sheen-router.md)
