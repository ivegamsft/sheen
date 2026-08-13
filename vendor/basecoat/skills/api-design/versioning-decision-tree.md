# Versioning Decision Tree

Use this decision tree to determine the correct versioning action for any API change.

---

## Decision Flow

```
Is this a new API with no existing consumers?
├── YES → Start at v1. No further action.
└── NO → Continue.

Does the change modify an existing endpoint, field, or schema?
├── NO → (New endpoint or new optional field only)
│   └── Add to the current version. No version bump needed.
└── YES → Continue.

Is the change breaking? (See breaking-change-checklist.md)
├── NO → (Non-breaking modification)
│   └── Add to the current version. Document in changelog.
└── YES → Continue.

Can the breaking change be made non-breaking with a compatibility strategy?
├── YES → Apply the strategy:
│   ├── Add new field alongside old field → deprecate old field
│   ├── Support both old and new query parameter names
│   ├── Add redirect from old path to new path
│   └── Deploy to current version with deprecation notices.
└── NO → A new major version is required. Continue.

Create new major version:
├── Increment version (v1 → v2).
├── Draft migration guide.
├── Set deprecation timeline for old version (minimum 90 days).
├── Publish changelog entry.
└── File GitHub Issue with label `api-design,breaking-change`.
```

---

## Versioning Scheme

| Component | Format | Example |
|---|---|---|
| URL prefix | `/v{major}/` | `/v1/orders`, `/v2/orders` |
| Spec version | `{major}.{minor}.{patch}` | `1.2.0`, `2.0.0` |
| Header (alternative) | `Accept: application/vnd.{api}.v{major}+json` | `Accept: application/vnd.myapi.v2+json` |

### When to Increment

| Change Type | Version Action | Example |
|---|---|---|
| Bug fix to spec docs (no behavior change) | Patch bump | `1.0.0` → `1.0.1` |
| Add optional field, new endpoint, new enum value | Minor bump | `1.0.0` → `1.1.0` |
| Remove field, change type, remove endpoint | Major bump | `1.0.0` → `2.0.0` |

---

## URL-Prefix Versioning (Default)

Use URL-prefix versioning as the default strategy:

```
https://api.example.com/v1/orders
https://api.example.com/v2/orders
```

**Rules:**
- The major version appears in the URL path.
- Minor and patch versions are not exposed in the URL — they are tracked in the spec only.
- Both `/v1/` and `/v2/` must remain functional during the deprecation period.
- Route both versions to the same service if possible, with internal branching.

---

## Header-Based Versioning (Alternative)

Use header-based versioning when URL prefixes are impractical (e.g., hypermedia APIs, shared resource paths):

```
Accept: application/vnd.myapi.v1+json
Accept: application/vnd.myapi.v2+json
```

**Rules:**
- If no version header is provided, default to the latest stable version.
- Return `406 Not Acceptable` if the requested version is not supported.
- Document the accepted version headers in the spec.

---

## Deprecation Policy

| Phase | Duration | Action |
|---|---|---|
| Announcement | Immediately | Add `Sunset` header, update docs, notify consumers |
| Deprecation | Minimum 90 days | Return `Deprecation` header on responses, log usage |
| Removal | After deprecation period | Remove the old version, return `410 Gone` |

### Response Headers During Deprecation

```http
HTTP/1.1 200 OK
Sunset: Sat, 01 Mar 2025 00:00:00 GMT
Deprecation: true
Link: <https://api.example.com/v2/orders>; rel="successor-version"
```

---

## Decision Checklist

Use this checklist in your PR description:

- [ ] Change classified as breaking / non-breaking
- [ ] Correct version action determined (patch / minor / major)
- [ ] If major: migration guide drafted
- [ ] If major: deprecation timeline set (minimum 90 days)
- [ ] Changelog entry written
- [ ] Spec `info.version` field updated
- [ ] URL prefix updated (if major bump)
