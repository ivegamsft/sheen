# Tool Definition Template

Use this template to define a single MCP tool. Replace all `<placeholder>` values. One file per tool keeps definitions reviewable and composable.

---

## Tool Contract

Define the tool's interface before writing the handler.

```
Tool name: <tool-name>            (kebab-case, e.g., query-database, create-issue)
Description: <what the tool does, when to use it, and any side effects>
Destructive: <yes | no>           (does this tool mutate external state?)
Idempotent: <yes | no>            (is it safe to retry on failure?)
Auth required: <scope or role>    (what permission is needed to invoke this tool)
```

---

## Input Schema

Define the JSON Schema for the tool's parameters.

```json
{
  "type": "object",
  "properties": {
    "<param1>": {
      "type": "string",
      "description": "<what this parameter controls>"
    },
    "<param2>": {
      "type": "integer",
      "description": "<what this parameter controls>",
      "minimum": 1,
      "maximum": 100
    },
    "<param3>": {
      "type": "boolean",
      "description": "<what this flag enables>",
      "default": false
    }
  },
  "required": ["<param1>"],
  "additionalProperties": false
}
```

---

## Handler Pseudocode

```
async function handle_<tool_name>(params, context) {

  // 1. Validate inputs beyond schema constraints
  if (!isValid(params.<param1>)) {
    return errorResult("INVALID_INPUT", "param1 must be ...")
  }

  // 2. Check authorization
  if (!context.hasScope("<required-scope>")) {
    return errorResult("FORBIDDEN", "Requires <required-scope> scope")
  }

  // 3. Execute tool logic
  try {
    const result = await performAction(params)

    // 4. Log success
    logger.info({
      event: "tool.<tool-name>.success",
      correlationId: context.correlationId,
      summary: "<brief outcome>"
    })

    // 5. Return structured result
    return {
      content: [
        { type: "text", text: JSON.stringify(result) }
      ]
    }
  } catch (error) {
    // 6. Handle and log failure
    logger.error({
      event: "tool.<tool-name>.error",
      correlationId: context.correlationId,
      error: error.message
    })

    return {
      content: [
        { type: "text", text: "Tool execution failed: " + error.message }
      ],
      isError: true
    }
  }
}
```

---

## Output Shape

Document the structure callers should expect on success.

```json
{
  "content": [
    {
      "type": "text",
      "text": "{\"id\": \"<entity-id>\", \"status\": \"<outcome>\", \"details\": { ... }}"
    }
  ]
}
```

On error, set `isError: true` and return a human-readable message in the content text.

---

## Testing Checklist

- [ ] Happy path returns expected output structure
- [ ] Missing required parameters returns clear validation error
- [ ] Invalid parameter values rejected with field-level detail
- [ ] Unauthorized invocation returns forbidden error (not a crash)
- [ ] External dependency failure handled gracefully (timeout, network error)
- [ ] Destructive tools log the mutation for audit trail
- [ ] Handler does not leak secrets, PII, or internal stack traces in responses
