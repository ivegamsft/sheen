# Breaking-Change Checklist

Use this checklist before merging any API spec change. Evaluate every modification against the tables below. If any breaking change is detected, a new major version is required along with a migration plan.

---

## How to Use

1. List every field, endpoint, parameter, and schema that changed in the diff.
2. Classify each change using the tables below.
3. If any change is marked **Breaking**, stop and follow the mitigation steps.
4. Document results in the PR description.

---

## Response Schema Changes

| Change | Breaking? | Mitigation |
|---|---|---|
| Add optional field to response | No | — |
| Add required field to response | No | Consumers should ignore unknown fields |
| Remove a field from response | **Yes** | Deprecate first, remove in next major version |
| Rename a field | **Yes** | Add new field, deprecate old, remove in next major version |
| Change field type (e.g., string → integer) | **Yes** | New major version required |
| Change field format (e.g., date → date-time) | **Yes** | New major version required |
| Change field from nullable to non-nullable | **Yes** | New major version required |
| Change field from non-nullable to nullable | No | Consumers should already handle null |
| Narrow an enum (remove values) | **Yes** | Deprecate values first, remove in next major version |
| Widen an enum (add values) | No | Consumers should handle unknown enum values gracefully |

## Request Schema Changes

| Change | Breaking? | Mitigation |
|---|---|---|
| Add optional field to request | No | — |
| Make an optional field required | **Yes** | New major version required |
| Remove a field from request | No | Server ignores unknown fields |
| Change field type | **Yes** | New major version required |
| Narrow validation (reject previously valid input) | **Yes** | New major version or feature flag |
| Widen validation (accept previously invalid input) | No | — |
| Widen a request enum (add accepted values) | No | — |
| Narrow a request enum (reject previously accepted values) | **Yes** | New major version required |

## Endpoint and Path Changes

| Change | Breaking? | Mitigation |
|---|---|---|
| Add a new endpoint | No | — |
| Remove an endpoint | **Yes** | Deprecate first, remove in next major version |
| Change HTTP method | **Yes** | Add new method, deprecate old |
| Change URL path | **Yes** | Redirect from old path, deprecate, remove in next major version |
| Change query parameter name | **Yes** | Support both old and new names during transition |
| Remove a query parameter | **Yes** | Deprecate first |
| Change path parameter format | **Yes** | New major version required |

## Authentication and Authorization Changes

| Change | Breaking? | Mitigation |
|---|---|---|
| Change auth scheme (e.g., API key → OAuth) | **Yes** | Support both during transition period |
| Add auth to a previously public endpoint | **Yes** | Announce in advance, provide migration guide |
| Remove auth from an endpoint | No | But review security implications |
| Change required scopes or roles | **Yes** | Communicate changes, update consumer grants |

## Behavioral Changes

| Change | Breaking? | Mitigation |
|---|---|---|
| Change default pagination size | No | But document the change |
| Change sort order default | No | But document the change |
| Change error response structure | **Yes** | New major version required |
| Change rate limiting thresholds | No | But document and announce |
| Change from sync to async processing | **Yes** | New major version or opt-in header |

---

## When a Breaking Change Is Detected

1. **Do not merge into the current version.** A new major version is required.
2. **Draft a migration guide** that explains what changed, why, and how consumers should update.
3. **Set a deprecation timeline** for the old version (minimum two release cycles or 90 days).
4. **File a GitHub Issue** with the label `api-design,breaking-change` documenting the change and migration plan.
5. **Publish a changelog entry** for the new version.

---

## PR Description Template

Include this summary in every PR that modifies an API spec:

```markdown
## API Change Summary

- **Endpoints affected:** <list>
- **Breaking changes:** Yes / No
- **New version required:** Yes / No
- **Migration guide:** <link or inline>
- **Deprecation timeline:** <date or N/A>
- **Governance checklist passed:** Yes / No
```
