# DDD & CQRS Patterns

## Bounded Contexts & Aggregates

```python
from dataclasses import dataclass
from enum import Enum

class OrderStatus(Enum):
    PENDING = "pending"
    CONFIRMED = "confirmed"
    SHIPPED = "shipped"

@dataclass
class Money:
    """Value object - immutable."""
    amount: float
    currency: str

@dataclass
class Order:
    """Aggregate root - owns order lines."""
    order_id: str
    customer_id: str
    status: OrderStatus
    total_price: Money
    items: list

    def add_item(self, item):
        """Enforce invariant: Cannot modify shipped order."""
        if self.status == OrderStatus.SHIPPED:
            raise ValueError("Cannot modify shipped order")
        self.items.append(item)
```

## Event Sourcing

```python
@dataclass
class DomainEvent:
    aggregate_id: str

@dataclass
class OrderCreated(DomainEvent):
    customer_id: str
    total_price: float

class EventStore:
    def append(self, event: DomainEvent):
        """Append event to immutable log."""
        self.events.append(event)

    def rebuild_aggregate(self, aggregate_id: str) -> Order:
        """Reconstruct state from events."""
        events = [e for e in self.events if e.aggregate_id == aggregate_id]
        # Replay events to rebuild state
        return None
```

## CQRS Pattern

```python
# Commands - modify state
class CreateOrderCommand:
    pass

# Queries - read state
class GetOrderQuery:
    pass

class OrderCommandHandler:
    def handle_create_order(self, cmd: CreateOrderCommand):
        pass  # Modify state

class OrderQueryHandler:
    def handle_get_order(self, query: GetOrderQuery):
        pass  # Query read model
```

## Saga Pattern

```python
class OrderSaga:
    def start(self, order):
        payment_result = self.payment_service.reserve(order)
        if not payment_result.success:
            self.compensate_payment()
            return

        inventory_result = self.inventory_service.reserve(order)
        if not inventory_result.success:
            self.compensate_payment()
            self.compensate_inventory()
            return
```
