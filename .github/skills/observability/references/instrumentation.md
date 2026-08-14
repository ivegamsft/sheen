# Observability Instrumentation Patterns

## OpenTelemetry — Flask (Python)

```python
from opentelemetry import trace
from opentelemetry.instrumentation.flask import FlaskInstrumentor
from opentelemetry.sdk.trace import TracerProvider

trace.set_tracer_provider(TracerProvider())
FlaskInstrumentor().instrument_app(app)
tracer = trace.get_tracer("checkout-service")

@app.get("/checkout")
def checkout():
    with tracer.start_as_current_span("checkout") as span:
        span.set_attribute("http.route", "/checkout")
        span.set_attribute("app.feature", "cart")
        logger.info("checkout_started", extra={"trace_id": format(span.get_span_context().trace_id, 'x')})
        return {"status": "ok"}
```

## Structured Log Fields

Always include: `severity`, `service`, `environment`, `operation`, `trace_id` / `request_id`.

Logs should describe state transitions and failures — not duplicate every implementation detail.
A good log lets responders answer: what failed, where, and for whom.

## Metric Design Rules

- Prefer a small set of high-value counters, histograms, and gauges
- Track: request volume, latency, error rate, saturation, queue depth, retry behavior
- Keep label cardinality low — no user IDs or raw URLs as dimensions
- Metrics must produce alertable signals and support trend analysis

## Span Attributes

Create spans around externally meaningful work: HTTP handlers, DB calls, queue consumers,
third-party requests.

Add attributes for: route, dependency name, status code, tenant-safe business context.
Traces should return an end-to-end view of latency and causality across distributed systems.

## References

- [OpenTelemetry Python SDK](https://opentelemetry-python.readthedocs.io/)
- [OTEL instrumentation guide](https://opentelemetry.io/docs/instrumentation/)
