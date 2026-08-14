# Transport Configuration Template

Use this template to configure an MCP server transport. Choose the section matching your deployment model and adapt to your language and SDK.

---

## Transport Selection Guide

| Criterion | stdio | SSE | Streamable HTTP |
|---|---|---|---|
| Deployment | Local / same machine | Web / behind proxy | Web / production |
| Multi-client | No (1:1 process) | Yes | Yes |
| Bidirectional | Yes (stdin/stdout) | No (server→client only, POST for reverse) | Yes |
| TLS required | No | Yes (production) | Yes (production) |
| Session support | Implicit (process) | Requires session management | Built-in |
| Recommended for | CLI tools, editor plugins, local dev | Legacy browser integrations | New production deployments |

---

## stdio Configuration

Use for local integrations where the client spawns the server as a child process.

```
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio"

const transport = new StdioServerTransport()
await server.connect(transport)
```

Configuration notes:

- No network configuration needed — communication is over stdin/stdout.
- Server lifecycle is tied to the parent process. Implement graceful shutdown on SIGTERM/SIGINT.
- Do not write non-protocol output to stdout. Use stderr for logging.
- Set `MCP_LOG_LEVEL` via environment variable for debug output to stderr.

---

## SSE Configuration

Use for server-push scenarios or browser-based clients.

```
import { SSEServerTransport } from "@modelcontextprotocol/sdk/server/sse"
import express from "express"

const app = express()

app.get("/sse", async (req, res) => {
  const transport = new SSEServerTransport("/messages", res)
  await server.connect(transport)
})

app.post("/messages", async (req, res) => {
  // Route client messages to the transport
  await transport.handlePostMessage(req, res)
})

app.listen(process.env.MCP_SERVER_PORT || 3000)
```

Configuration notes:

- Pair the SSE endpoint (GET) with a message endpoint (POST) for bidirectional communication.
- Set `Cache-Control: no-cache` and `Connection: keep-alive` headers on the SSE response.
- Configure proxy/load balancer to disable response buffering for the SSE endpoint.
- Implement session tracking if serving multiple concurrent clients.
- Set idle timeout to detect and clean up stale connections.

---

## Streamable HTTP Configuration

Preferred for new production deployments. Supports full bidirectional communication over HTTP.

```
import { StreamableHTTPServerTransport } from "@modelcontextprotocol/sdk/server/streamableHttp"
import express from "express"

const app = express()

app.post("/mcp", async (req, res) => {
  const transport = new StreamableHTTPServerTransport({
    sessionIdGenerator: () => crypto.randomUUID(),
    onsessioninitialized: (sessionId) => {
      // Track active session
    }
  })
  await server.connect(transport)
  await transport.handleRequest(req, res)
})

// Optional: session management endpoints
app.get("/mcp", async (req, res) => {
  // Handle SSE streaming for server-initiated messages
})

app.delete("/mcp", async (req, res) => {
  // Handle session termination
})

app.listen(process.env.MCP_SERVER_PORT || 3000)
```

Configuration notes:

- Use a single endpoint path for all MCP operations (POST for requests, GET for streaming, DELETE for teardown).
- Generate unique session IDs and track active sessions for cleanup.
- Deploy behind a reverse proxy with TLS termination.
- Set request body size limits to prevent abuse.

---

## Common Transport Settings

Apply these settings regardless of transport choice.

| Setting | Recommended value | Purpose |
|---|---|---|
| Connection timeout | 10 seconds | Fail fast on unreachable servers |
| Request timeout | 30 seconds | Prevent runaway tool execution |
| Idle timeout | 300 seconds | Clean up inactive connections |
| Max request size | 1 MB | Prevent oversized payloads |
| Keep-alive interval | 30 seconds | Detect dead connections (SSE/HTTP) |
| Reconnect backoff | Exponential, 1–60 seconds | Avoid thundering herd on recovery |

---

## TLS and Security

- Enable TLS for any transport exposed beyond localhost. Use certificates from a trusted CA or your organization's PKI.
- Set CORS policies when serving browser-based clients. Never use wildcard origins in production.
- Validate the `Origin` header on SSE and HTTP transports to prevent unauthorized cross-origin access.
- Rate-limit connection attempts and tool invocations to mitigate abuse.

---

## Health Check

Expose a health endpoint for HTTP-based transports.

```
app.get("/health", (req, res) => {
  res.status(200).json({
    status: "ok",
    server: "<server-name>",
    version: "<1.0.0>",
    uptime: process.uptime()
  })
})
```

Use this endpoint for:

- Kubernetes liveness and readiness probes
- Load balancer health checks
- Monitoring and alerting systems
