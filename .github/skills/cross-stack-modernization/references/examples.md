# Cross-Stack Modernization — Examples

## Risk Scoring a Service Portfolio

```text
Service A: Complexity=1, Coupling=1, Coverage=80% → Risk = 1×1×(1/0.8) = 1.25  ✅ migrate first
Service B: Complexity=2, Coupling=2, Coverage=40% → Risk = 2×2×(1/0.4) = 10    ⚠ mid-queue
Service C: Complexity=3, Coupling=3, Coverage=10% → Risk = 3×3×(1/0.1) = 90    🔴 migrate last
```

## Strangler Fig Routing with nginx

```nginx
location /api/orders {
    # New orders service
    proxy_pass http://orders-new.internal;
}

location /api/ {
    # Legacy catch-all (shrinks over time)
    proxy_pass http://legacy-api.internal;
}
```

## ACL Adapter (TypeScript)

```typescript
// Domain interface — new code depends only on this
interface OrderRepository {
  findById(id: string): Promise<Order>;
}

// ACL implementation wrapping legacy REST API
class LegacyOrderAdapter implements OrderRepository {
  async findById(id: string): Promise<Order> {
    const raw = await legacyClient.get(`/orders/${id}`);
    return {
      id: raw.order_id,           // legacy uses snake_case
      total: raw.total_amount_usd,
      status: mapLegacyStatus(raw.status_code),
    };
  }
}
```

## Output Artifacts

- Migration strategy decision (refactor / strangler fig / rewrite) with rationale
- Risk scores per service and recommended extraction sequence
- ACL interface definitions for wrapped legacy APIs
- Database-first or UI-first selection with transition plan
- Routing proxy configuration for strangler fig (if applicable)
