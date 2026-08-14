# API Governance Checklist

Every API spec must pass this checklist before approval. No exceptions. If a rule is marked **Required**, the spec must not be merged until it passes. If marked **Recommended**, document the reason for any deviation.

---

## How to Use

1. Run through every item in this checklist before approving an API spec PR.
2. Mark each item as passing, failing, or not applicable.
3. Include the results in the PR description.
4. File a GitHub Issue for any failing required item.

---

## Naming and Consistency

| # | Rule | Severity |
|---|---|---|
| N1 | Resource names use plural nouns (`/orders`, not `/order`) | Required |
| N2 | JSON field names use `camelCase` | Required |
| N3 | URL path segments use `kebab-case` (`/order-items`, not `/orderItems`) | Required |
| N4 | Query parameter names use `camelCase` | Required |
| N5 | Enum values use `UPPER_SNAKE_CASE` | Recommended |
| N6 | Operation IDs follow the pattern `{verb}{Resource}` (e.g., `listOrders`, `getOrder`) | Required |
| N7 | No abbreviations in field or resource names unless universally understood (`id`, `url`, `http`) | Recommended |

## Authentication and Authorization

| # | Rule | Severity |
|---|---|---|
| A1 | Every endpoint has an explicit `security` definition | Required |
| A2 | Public endpoints are explicitly marked with `security: []` | Required |
| A3 | Auth scheme is documented in `components/securitySchemes` | Required |
| A4 | Required scopes or roles are documented per endpoint | Required |
| A5 | No endpoint is implicitly public (missing security means not-yet-defined, not public) | Required |

## Request and Response Design

| # | Rule | Severity |
|---|---|---|
| R1 | Every request and response schema has a `description` | Required |
| R2 | Every field has a `type` and `description` | Required |
| R3 | Required fields are listed in the `required` array | Required |
| R4 | All date/time fields use ISO 8601 format (`date-time`) | Required |
| R5 | IDs use `string` type with `format: uuid` unless there is a documented reason for another format | Recommended |
| R6 | Responses include `example` values for at least one success and one error case | Recommended |
| R7 | Request bodies use dedicated `Create*Request` and `Update*Request` schemas, not the resource schema directly | Required |

## Pagination

| # | Rule | Severity |
|---|---|---|
| P1 | All collection endpoints support pagination | Required |
| P2 | Pagination uses cursor-based or offset+limit pattern | Required |
| P3 | Response includes `total`, `pageSize`, and `nextCursor` (or equivalent) | Required |
| P4 | Default page size is documented and capped (e.g., max 100) | Required |
| P5 | Empty collections return `200` with an empty `data` array, not `404` | Required |

## Error Handling

| # | Rule | Severity |
|---|---|---|
| E1 | All non-2xx responses use the standard `ErrorEnvelope` schema | Required |
| E2 | Every error code is documented in the error catalog | Required |
| E3 | Error messages are human-readable and do not expose internal details | Required |
| E4 | `correlationId` is present in every error response | Required |
| E5 | `422` responses include field-level `details` | Required |
| E6 | `429` responses include a `Retry-After` header | Recommended |

## Versioning and Deprecation

| # | Rule | Severity |
|---|---|---|
| V1 | `info.version` matches the current spec version in semver format | Required |
| V2 | URL prefix includes the major version (`/v1/`) | Required |
| V3 | No breaking changes in the current version (use breaking-change checklist) | Required |
| V4 | Deprecated fields are marked with `deprecated: true` and a description explaining the replacement | Required |
| V5 | Sunset timeline is documented for any deprecated endpoint or field | Required |
| V6 | Changelog entry exists for every version increment | Recommended |

## Documentation

| # | Rule | Severity |
|---|---|---|
| D1 | `info.title` and `info.description` are present and meaningful | Required |
| D2 | `info.contact` includes team name and email | Recommended |
| D3 | Every endpoint has a `summary` and `description` | Required |
| D4 | Every tag is used by at least one endpoint | Required |
| D5 | Server URLs are defined for all environments (production, staging) | Recommended |
| D6 | Rate limiting policy is documented in spec description or a linked document | Recommended |

## Security

| # | Rule | Severity |
|---|---|---|
| S1 | No sensitive data (passwords, tokens, secrets) in query parameters | Required |
| S2 | PII fields are identified and documented | Required |
| S3 | CORS policy is documented or referenced | Recommended |
| S4 | Rate limiting is configured for all public-facing endpoints | Required |
| S5 | Input validation constraints (min, max, pattern, maxLength) are defined on all request fields | Recommended |

---

## PR Description Template

Include this summary in every PR that introduces or modifies an API spec:

```markdown
## API Governance Review

- **Naming (N1–N7):** ✅ All pass / ❌ <list failures>
- **Auth (A1–A5):** ✅ All pass / ❌ <list failures>
- **Request/Response (R1–R7):** ✅ All pass / ❌ <list failures>
- **Pagination (P1–P5):** ✅ All pass / ❌ <list failures>
- **Errors (E1–E6):** ✅ All pass / ❌ <list failures>
- **Versioning (V1–V6):** ✅ All pass / ❌ <list failures>
- **Docs (D1–D6):** ✅ All pass / ❌ <list failures>
- **Security (S1–S5):** ✅ All pass / ❌ <list failures>
- **Issues filed:** <list issue numbers or "None">
```
