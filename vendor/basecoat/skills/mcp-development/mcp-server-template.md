# MCP Server Template

Use this template to scaffold an MCP server. Replace all `<placeholder>` values. The pattern is SDK-agnostic — adapt the syntax to the language and MCP SDK in use.

---

## Server Metadata

Define the server identity and capabilities before writing handlers.

```
Server name: <server-name>
Version: <1.0.0>
Description: <what this server does and what domain it covers>
Capabilities: <tools | resources | prompts — list what the server exposes>
```

---

## Pseudocode Scaffold

The following scaffold shows the expected structure. Implement in the project language using the official MCP SDK.

```
import { McpServer } from "@modelcontextprotocol/sdk/server"
import { StdioTransport } from "@modelcontextprotocol/sdk/transports"

// -----------------------------------------------------------------------
// 1. Create server instance
// -----------------------------------------------------------------------

const server = new McpServer({
  name: "<server-name>",
  version: "<1.0.0>",
  description: "<what this server does>"
})

// -----------------------------------------------------------------------
// 2. Register tools
// -----------------------------------------------------------------------

server.tool(
  "<tool-name>",
  "<tool description — explain what it does, when to use it, and side effects>",
  {
    // JSON Schema for input parameters
    <param1>: { type: "string", description: "<what this parameter controls>" },
    <param2>: { type: "number", description: "<what this parameter controls>" }
  },
  async ({ <param1>, <param2> }) => {
    // Validate inputs beyond schema (business rules)
    // Execute tool logic
    // Return structured result
    return {
      content: [
        { type: "text", text: JSON.stringify(result) }
      ]
    }
  }
)

// Register additional tools following the same pattern...

// -----------------------------------------------------------------------
// 3. Register resources (if applicable)
// -----------------------------------------------------------------------

server.resource(
  "<resource-name>",
  "<resource-uri-template>",
  async (uri) => {
    // Fetch and return resource content
    return {
      contents: [
        { uri: uri.href, mimeType: "application/json", text: JSON.stringify(data) }
      ]
    }
  }
)

// -----------------------------------------------------------------------
// 4. Connect transport and start
// -----------------------------------------------------------------------

async function main() {
  const transport = new StdioTransport()
  await server.connect(transport)
  // Server is now running and accepting requests
}

main().catch((error) => {
  console.error("Server failed to start:", error)
  process.exit(1)
})
```

---

## Lifecycle Checklist

- [ ] Server declares name, version, and capabilities
- [ ] All tools registered before transport connection
- [ ] Graceful shutdown handler implemented (close connections, flush logs)
- [ ] Entry point handles startup errors and exits with non-zero code on failure
- [ ] Health check endpoint exposed (for HTTP transports)

---

## Configuration

Use environment variables for all runtime settings. Never hardcode values.

| Variable | Purpose | Default |
|---|---|---|
| `MCP_SERVER_PORT` | HTTP/SSE listen port | `3000` |
| `MCP_LOG_LEVEL` | Logging verbosity | `info` |
| `MCP_AUTH_TOKEN` | Bearer token for authentication | _(required, no default)_ |
| `MCP_TIMEOUT_MS` | Request timeout in milliseconds | `30000` |

---

## Error Handling

- Catch all exceptions in tool handlers. Never let an unhandled error crash the server.
- Return MCP-compliant error responses with meaningful error codes and messages.
- Log errors with context (tool name, input summary, correlation ID) but never log secrets or full request bodies.
- Distinguish between client errors (invalid input) and server errors (internal failure) in response codes.
