---
name: otel-instrumentation
title: OpenTelemetry Instrumentation & Observability
description: Distributed tracing, metrics collection, trace sampling, instrumentation patterns
compatibility: ["agent:observability"]
metadata:
  domain: observability
  maturity: production
  audience: [sre, backend-engineer, devops-engineer]
allowed-tools: [python, javascript, go, bash]
---

# OpenTelemetry Instrumentation Skill

Patterns for instrumenting applications with OpenTelemetry for distributed tracing and metrics.

## Python Distributed Tracing

```python
from opentelemetry import trace
from opentelemetry.exporter.otlp.proto.grpc.trace_exporter import OTLPSpanExporter
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor
from opentelemetry.instrumentation.flask import FlaskInstrumentor

# Configure OTLP exporter
otlp_exporter = OTLPSpanExporter(endpoint="otel-collector:4317")

# Set up tracer provider
trace.set_tracer_provider(TracerProvider())
trace.get_tracer_provider().add_span_processor(
    BatchSpanProcessor(otlp_exporter)
)

# Auto-instrument Flask
FlaskInstrumentor().instrument()

# Manual tracing
tracer = trace.get_tracer("my-app")

@app.route("/api/orders")
def list_orders():
    with tracer.start_as_current_span("list_orders") as span:
        span.set_attribute("user_id", request.args.get("user_id"))
        orders = fetch_orders()
        span.set_attribute("order_count", len(orders))
        return {"orders": orders}
```

## Metrics Collection

```python
from opentelemetry import metrics
from opentelemetry.exporter.otlp.proto.grpc.metric_exporter import OTLPMetricExporter
from opentelemetry.sdk.metrics import MeterProvider

# Configure metrics
metric_reader = PeriodicExportingMetricReader(
    OTLPMetricExporter(endpoint="otel-collector:4317")
)
metrics.set_meter_provider(MeterProvider(metric_readers=[metric_reader]))
meter = metrics.get_meter("my-app")

# Create instruments
request_counter = meter.create_counter("http_requests_total")
request_duration = meter.create_histogram("http_request_duration_seconds")

@app.route("/api/orders")
def list_orders():
    start = time.time()
    try:
        orders = fetch_orders()
        request_counter.add(1, {"status": 200})
        return {"orders": orders}
    finally:
        request_duration.record(time.time() - start)
```

## Trace Sampling

```python
from opentelemetry.sdk.trace.sampling import TraceIdRatioBased

# Sample 10% of traces
sampler = TraceIdRatioBased(0.1)

trace.set_tracer_provider(
    TracerProvider(sampler=sampler)
)
```

## Context Propagation

```python
from opentelemetry.propagate import inject

headers = {}
inject(headers)

# Make downstream request with trace context
response = httpx.get(
    "https://downstream-service/api/data",
    headers=headers
)
```

## Correlation IDs

```python
from opentelemetry.trace import get_current_span

@app.route("/api/orders")
def list_orders():
    span = get_current_span()
    trace_id = span.get_span_context().trace_id
    
    # Inject into logs and responses
    logger.info(f"Listing orders", extra={"trace_id": trace_id})
    response.headers["X-Trace-ID"] = trace_id
```

---

## References

- [OpenTelemetry](https://opentelemetry.io/)
- [Observability Engineering](https://www.oreilly.com/library/view/observability-engineering/)
