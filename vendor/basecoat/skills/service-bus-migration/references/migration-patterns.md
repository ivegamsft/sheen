# Service Bus Migration Patterns - Direct vs Gradual Migration Strategies

## Direct Lift-and-Shift
Simplest for straightforward messaging. Zero hybrid bridge complexity.

## Gradual Migration
Implement message routing layer with MSMQ→SB forwarding during transition. Includes correlation ID preservation and migration tracking.

## Topic/Subscription Mapping
Map MSMQ distribution lists to Service Bus topics+subscriptions. Content-based filtering replaces label-based routing.

## Message Serialization
Convert Binary Formatters → JSON. Includes legacy format detection and property preservation.
