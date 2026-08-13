# Dead-Letter Handling & Retry Policies

## Dead-Letter Queue Processing
Configure per-entity dead-letter handling with logging and analysis. Set MaxDeliveryCount (default: 10).

## Exponential Backoff
Retry formula: delay = minBackoff + (deltaBackoff × (2^attemptNumber - 1))
Typical: min=1s, max=30s, delta=2s

## Error Classification
- Transient: ServiceBusException(IsTransient), timeouts, network blips → RETRY
- Non-transient: Auth failures, malformed messages, data errors → DEAD-LETTER
