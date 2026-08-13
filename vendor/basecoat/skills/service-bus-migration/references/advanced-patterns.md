# Advanced Patterns - Outbox, Hybrid Bridge, Cutover Phases

## Outbox Pattern
Atomic event publishing without distributed transactions. Domain operation + outbox write in single DB transaction.

## Hybrid Bidirectional Bridge
Maintain MSMQ↔SB compatibility during gradual cutover. Metadata: Source tracking, BridgedAt timestamps.

## Migration Control Plane
Phase transitions via feature flags:
- Phase 0: MSMQ Only
- Phase 1: MSMQ Primary, SB Secondary (shadow)
- Phase 2: SB Primary, MSMQ Secondary (fallback)
- Phase 3: SB Only
