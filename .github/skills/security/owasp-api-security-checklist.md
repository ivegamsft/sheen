---
name: api-security
title: OWASP API Security Top 10 Checklist
description: Detailed checklist for OWASP API Security Top 10 (2023) risks with assessment criteria and remediation guidance
compatibility: ["agent:api-security", "agent:penetration-test"]
metadata:
  domain: security
  maturity: production
  audience: [security-engineer, api-designer, architect]
allowed-tools: [bash, python, curl, jq]
---

# OWASP API Security Top 10 Checklist (2023)

Comprehensive assessment framework for API-specific vulnerabilities. Use alongside OpenAPI specs and threat models.

## API1: Broken Object Level Authorization (BOLA)

**Risk:** Users can access objects belonging to other users by modifying object references (IDs).

**Assessment Criteria:**

- [ ] API implements authorization checks before returning user-specific objects
- [ ] Direct object references (IDs) cannot be enumerated or guessed (`GET /orders/999`, `GET /orders/1000`)
- [ ] Authenticated user cannot read/modify other users' resources by changing URL parameter
- [ ] Pagination does not leak object count or enable full enumeration

**Test Case:**

```bash
# Authenticate as user A
TOKEN_A=$(curl -X POST https://api.example.com/auth -d 'user=alice@example.com' -H 'Content-Type: application/json' | jq -r .token)

# Retrieve user A's order
curl -X GET https://api.example.com/orders/42 -H "Authorization: Bearer $TOKEN_A" | jq .
# Expected: Returns order for user A

# Attempt to access user B's order
curl -X GET https://api.example.com/orders/41 -H "Authorization: Bearer $TOKEN_A"
# Expected: 403 Forbidden or 404 Not Found
# VULNERABLE if returns user B's order data
```

**Remediation:**

```python
# Python Flask example
@app.route('/orders/<order_id>', methods=['GET'])
@require_auth
def get_order(order_id):
    # Fetch order
    order = Order.query.filter_by(id=order_id).first()
    if not order:
        return {"error": "Not found"}, 404
    
    # Verify current user owns this order
    if order.user_id != current_user.id:
        return {"error": "Unauthorized"}, 403
    
    return order.to_dict()
```

---

## API2: Broken Authentication

**Risk:** Weak or missing credential validation. Tokens not properly validated.

**Assessment Criteria:**

- [ ] Passwords meet OWASP requirements: minimum 12 characters, no common patterns
- [ ] JWT tokens have valid signature (RS256 or ES256, not HS256 with shared secret)
- [ ] JWT expiry enforced (typical: 15-60 minutes for access tokens)
- [ ] Refresh tokens used for long-lived sessions (typical: 7 days or less)
- [ ] API keys scoped to least-privilege operations
- [ ] MFA available for sensitive operations

**Test Case:**

```bash
# Test JWT validation
EXPIRED_TOKEN="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiZXhwIjoxNjAwMDAwMDAwfQ.3R-5E7"

curl -X GET https://api.example.com/profile -H "Authorization: Bearer $EXPIRED_TOKEN"
# Expected: 401 Unauthorized
# VULNERABLE if returns user data

# Test JWT signature bypass (HS256 vulnerability)
# If API accepts HS256, attacker can sign tokens with shared secret
```

**Remediation:**

```python
import jwt
from datetime import datetime, timedelta

# Generate tokens with expiry
def generate_token(user_id):
    payload = {
        'user_id': user_id,
        'exp': datetime.utcnow() + timedelta(minutes=15),
        'iat': datetime.utcnow()
    }
    return jwt.encode(payload, SECRET_KEY, algorithm='RS256')  # Use RS256

# Validate tokens
def verify_token(token):
    try:
        payload = jwt.decode(token, PUBLIC_KEY, algorithms=['RS256'])
        return payload['user_id']
    except jwt.ExpiredSignatureError:
        raise Unauthorized("Token expired")
    except jwt.InvalidSignatureError:
        raise Unauthorized("Invalid token")
```

---

## API3: Broken Object Property Level Authorization (Mass Assignment)

**Risk:** Users can set properties they shouldn't (e.g., `is_admin`, `user_role`).

**Assessment Criteria:**

- [ ] API only accepts explicitly allowed properties in request body (whitelist, not blacklist)
- [ ] Sensitive properties (id, created_at, is_admin, role) cannot be set by regular users
- [ ] Batch operations apply same property restrictions
- [ ] Response filtering matches request filtering (don't expose properties set by admin)

**Test Case:**

```bash
# Attempt mass assignment
curl -X POST https://api.example.com/users \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Attacker",
    "email": "attacker@example.com",
    "is_admin": true,  # Try to set privilege
    "account_tier": "enterprise"  # Try to set premium features
  }'

# VULNERABLE if response includes {"is_admin": true, "account_tier": "enterprise"}
```

**Remediation:**

```python
# Use request validation framework
from marshmallow import Schema, fields, validate

class CreateUserSchema(Schema):
    name = fields.Str(required=True, validate=validate.Length(min=1, max=255))
    email = fields.Email(required=True)
    # EXCLUDED: is_admin, account_tier (not in schema = not accepted)

@app.route('/users', methods=['POST'])
def create_user():
    # Parse only allowed fields
    schema = CreateUserSchema()
    user_data = schema.load(request.json)
    
    # Create user (is_admin defaults to False)
    user = User(**user_data, is_admin=False)
    db.session.add(user)
    db.session.commit()
    
    return user_data  # Only return allowed fields
```

---

## API4: Unrestricted Resource Consumption

**Risk:** API can be abused to consume excessive resources (DoS).

**Assessment Criteria:**

- [ ] Rate limiting enforced (e.g., 100 requests/minute per user)
- [ ] Request body size limited (e.g., 1 MB)
- [ ] Query parameter pagination enforced (e.g., max 100 items, default 20)
- [ ] Request timeout enforced (e.g., 30 seconds)
- [ ] Batch operations have size limits (e.g., max 100 items per batch)
- [ ] File uploads have size/type restrictions

**Test Case:**

```bash
# Test rate limiting
for i in {1..150}; do
  curl -X GET https://api.example.com/data \
    -H "Authorization: Bearer $TOKEN"
done

# Expected: After limit (e.g., 100 requests), returns 429 Too Many Requests
# VULNERABLE if all 150 requests succeed

# Test pagination limits
curl -X GET "https://api.example.com/users?limit=10000&offset=0" \
  -H "Authorization: Bearer $TOKEN"

# Expected: Returns max 100 items (or error if limit > max)
# VULNERABLE if returns 10,000 items
```

**Remediation:**

```python
from flask_limiter import Limiter
from flask_limiter.util import get_remote_address

limiter = Limiter(app, key_func=get_remote_address)

@app.route('/data', methods=['GET'])
@limiter.limit("100 per minute")  # Rate limiting
def get_data():
    limit = request.args.get('limit', default=20, type=int)
    limit = min(limit, 100)  # Cap at 100
    offset = request.args.get('offset', default=0, type=int)
    
    # Timeout applied implicitly by app config
    data = Data.query.offset(offset).limit(limit).all()
    return [d.to_dict() for d in data]
```

---

## API5: Broken Function Level Authorization

**Risk:** Users can call admin/privileged functions without authorization.

**Assessment Criteria:**

- [ ] All admin endpoints protected by role check (e.g., `@require_role('admin')`)
- [ ] User role verified on every request (not cached insecurely)
- [ ] API version-specific permissions enforced (v1 may have different auth than v2)
- [ ] Deprecated endpoints enforce same authorization as current versions

**Test Case:**

```bash
# Attempt to call admin endpoint as regular user
curl -X DELETE https://api.example.com/admin/users/999 \
  -H "Authorization: Bearer $REGULAR_USER_TOKEN"

# Expected: 403 Forbidden
# VULNERABLE if user/resource is deleted
```

**Remediation:**

```python
def require_role(required_role):
    def decorator(f):
        @wraps(f)
        def decorated_function(*args, **kwargs):
            token = request.headers.get('Authorization', '').replace('Bearer ', '')
            try:
                payload = jwt.decode(token, PUBLIC_KEY, algorithms=['RS256'])
                user_id = payload['user_id']
                user = User.query.get(user_id)
                
                if not user or user.role != required_role:
                    return {"error": "Forbidden"}, 403
                    
            except jwt.InvalidTokenError:
                return {"error": "Unauthorized"}, 401
            
            return f(*args, **kwargs)
        return decorated_function
    return decorator

@app.route('/admin/users/<user_id>', methods=['DELETE'])
@require_role('admin')
def delete_user(user_id):
    # Delete logic
    pass
```

---

## API6: Unrestricted Business Logic Flow

**Risk:** Workflow can be bypassed or executed out of order (e.g., purchase without payment).

**Assessment Criteria:**

- [ ] State machine enforced (order: `pending` → `processing` → `shipped` → `delivered`)
- [ ] Business operations require prerequisite steps to complete
- [ ] Transactional consistency: all-or-nothing updates (e.g., inventory + payment together)
- [ ] Concurrent requests handled safely (prevent race condition state corruption)

**Test Case:**

```bash
# Attempt to bypass order processing step
# Normal flow: Create order → Process payment → Ship order
# Attack: Create order → Ship order (skip payment)

curl -X POST https://api.example.com/orders \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"items": [...], "status": "shipped"}'  # Try to skip payment

# Expected: Order created with status = "pending"
# VULNERABLE if order is created with status = "shipped"

# Verify idempotency
curl -X POST https://api.example.com/orders/123/ship \
  -H "Authorization: Bearer $TOKEN"
# Expected: First call succeeds, second call returns error (order already shipped)
```

**Remediation:**

```python
class OrderStatus(Enum):
    PENDING = "pending"
    PROCESSING = "processing"
    SHIPPED = "shipped"
    DELIVERED = "delivered"

class Order:
    def ship(self):
        # Validate state machine
        if self.status != OrderStatus.PROCESSING:
            raise ValueError(f"Cannot ship order in {self.status} state")
        
        # Atomic transaction
        try:
            self.status = OrderStatus.SHIPPED
            self.shipped_at = datetime.utcnow()
            db.session.commit()
        except Exception:
            db.session.rollback()
            raise

@app.route('/orders/<order_id>/ship', methods=['POST'])
@require_role('fulfillment')
def ship_order(order_id):
    order = Order.query.get(order_id)
    if not order:
        return {"error": "Not found"}, 404
    
    try:
        order.ship()
    except ValueError as e:
        return {"error": str(e)}, 400
    
    return order.to_dict()
```

---

## API7: Server-Side Request Forgery (SSRF)

**Risk:** API makes requests to attacker-controlled URLs, accessing internal resources.

**Assessment Criteria:**

- [ ] URLs provided by users are validated against whitelist (not blacklist)
- [ ] File schemes (`file://`) disabled
- [ ] Private IP ranges blocked (169.254.x.x, 10.x.x.x, 172.16-31.x.x, 192.168.x.x, 127.x.x.x)
- [ ] DNS rebinding prevented (verify IP matches DNS after resolution)

**Test Case:**

```bash
# Attempt SSRF to internal resource
curl -X POST https://api.example.com/webhook-proxy \
  -d '{"url": "http://127.0.0.1:8080/admin"}'

# Expected: Blocked or 400 Bad Request
# VULNERABLE if response contains admin panel HTML

curl -X POST https://api.example.com/webhook-proxy \
  -d '{"url": "file:///etc/passwd"}'

# Expected: Error
# VULNERABLE if returns file contents
```

**Remediation:**

```python
import ipaddress
from urllib.parse import urlparse
import requests

PRIVATE_IP_RANGES = [
    ipaddress.ip_network('10.0.0.0/8'),
    ipaddress.ip_network('172.16.0.0/12'),
    ipaddress.ip_network('192.168.0.0/16'),
    ipaddress.ip_network('127.0.0.0/8'),
    ipaddress.ip_network('169.254.0.0/16'),
]

ALLOWED_DOMAINS = ['webhook.example.com', 'partner.example.com']

def is_ssrf_safe(url):
    parsed = urlparse(url)
    
    # Whitelist schemes
    if parsed.scheme not in ['http', 'https']:
        return False
    
    # Whitelist domains
    if parsed.netloc not in ALLOWED_DOMAINS:
        return False
    
    # Resolve hostname to IP
    import socket
    try:
        ip = socket.gethostbyname(parsed.hostname)
        ip_addr = ipaddress.ip_address(ip)
        
        # Block private IPs
        for private_range in PRIVATE_IP_RANGES:
            if ip_addr in private_range:
                return False
    except socket.error:
        return False
    
    return True

@app.route('/webhook-proxy', methods=['POST'])
def webhook_proxy():
    url = request.json.get('url')
    
    if not is_ssrf_safe(url):
        return {"error": "Invalid URL"}, 400
    
    response = requests.post(url, timeout=5)
    return {"status": response.status_code}
```

---

## API8: Improper Asset Management

**Risk:** Exposed or undocumented API endpoints (shadow APIs, test endpoints).

**Assessment Criteria:**

- [ ] API versioning policy documented (e.g., support N and N-1 versions)
- [ ] Old API versions deprecated with clear timeline (e.g., 12-month notice)
- [ ] Test/debug endpoints removed from production
- [ ] API documentation current and complete (OpenAPI/Swagger spec matches reality)
- [ ] Shadow APIs (undocumented endpoints) identified and cataloged or removed

**Test Case:**

```bash
# Scan for undocumented endpoints
# Check robots.txt, sitemap, OpenAPI spec for completeness

# Attempt common debug endpoints
curl https://api.example.com/debug
curl https://api.example.com/admin
curl https://api.example.com/health/detailed  # May expose internals
curl https://api.example.com/v1/users  # Old version still accessible?

# Verify OpenAPI spec matches implementation
# Generate request log for 7 days
# Compare endpoints in logs to endpoints in OpenAPI spec
```

**Remediation:**

```yaml
# Document API lifecycle
API Versioning Policy:
  Current Version: v3
  Supported Versions: v3, v2
  Deprecated: v1 (sunset 2025-01-01)
  
  End-of-Life:
    - v1: Sunset 2024-12-31, all traffic redirected to v2 with breaking change warnings
    - v2: Sunset 2025-12-31
  
  Breaking Changes:
    - v3: Removed deprecated fields, changed response format

# Remove test endpoints
# ❌ WRONG: Test endpoints in production
# GET /api/v1/users (test endpoint)
# POST /api/v1/debug/clear-cache
# DELETE /api/v1/admin/reset-database

# ✅ RIGHT: Test endpoints in test environment only
# Separate deployment for staging/QA
# No debug endpoints in production
```

---

## API9: Improper Inventory Management

**Risk:** Unknown or unpatched APIs that may be vulnerable.

**Assessment Criteria:**

- [ ] Complete API inventory maintained (OpenAPI specs for all APIs)
- [ ] APIs classified by sensitivity (public, internal, partner, restricted)
- [ ] API owners assigned for each endpoint
- [ ] Change tracking: API modifications require approvals
- [ ] Monitoring: API health, performance, error rates tracked

**Test Case:**

```bash
# Audit API inventory
# 1. Collect all OpenAPI specs
# 2. For each endpoint, verify:
#    - Owner assigned
#    - Documentation current
#    - Deployment tracked (which environments)
#    - Deprecation status (if old)

# 3. Identify gaps: Endpoints in production not in spec
openapi_endpoints=$(cat openapi.yaml | jq '.paths | keys')
actual_endpoints=$(curl https://api.example.com/__internal/endpoints | jq '.endpoints')
# Compare to find shadow APIs
```

**Remediation:**

```yaml
# Maintain API inventory
API Registry:
  - endpoint: POST /orders
    version: v3
    owner: order-service-team
    classification: internal
    created: 2023-01-15
    modified: 2024-05-20
    status: active
    dependencies: [payment-service, inventory-service]
    
  - endpoint: GET /users
    version: v2
    owner: user-service-team
    classification: partner
    created: 2022-06-01
    modified: 2024-03-10
    status: deprecated (sunset: 2025-06-01)
    successor: GET /users (v3)
    
  - endpoint: DELETE /admin/cache
    version: v1
    classification: restricted
    status: test-only (not in production)
    environment: dev, staging
```

---

## API10: Unsafe Consumption of APIs

**Risk:** Vulnerable when consuming third-party APIs (no validation, timeouts).

**Assessment Criteria:**

- [ ] Third-party API responses validated (schema, size limits)
- [ ] Timeouts enforced on all external calls (e.g., 10 seconds)
- [ ] Retries use exponential backoff, bounded
- [ ] Partial failures don't corrupt data (idempotent operations)
- [ ] Third-party credentials stored securely (not hardcoded, rotated regularly)

**Test Case:**

```bash
# Simulate third-party API failure
# 1. Mock third-party service to return invalid response
# 2. Verify application handles gracefully:
#    - Timeout triggered
#    - Error logged
#    - User notified (not system error)
#    - Retry attempted (if transient failure)

# 3. Verify response schema validation
# Inject unexpected fields, test parsing
```

**Remediation:**

```python
import httpx
from tenacity import retry, stop_after_attempt, wait_exponential

@retry(
    stop=stop_after_attempt(3),
    wait=wait_exponential(multiplier=1, min=2, max=10)
)
def call_payment_gateway(order_id, amount):
    try:
        # Timeout enforced
        response = httpx.post(
            'https://payment-gateway.example.com/charge',
            json={'order_id': order_id, 'amount': amount},
            timeout=10  # 10 second timeout
        )
        response.raise_for_status()
        
        # Validate response schema
        data = response.json()
        assert 'transaction_id' in data
        assert isinstance(data['transaction_id'], str)
        
        return data
        
    except httpx.TimeoutException:
        # Timeout: retry (exponential backoff)
        raise
    except httpx.HTTPError as e:
        # HTTP error: check if transient
        if e.response.status_code >= 500:
            raise  # Server error: retry
        else:
            # Client error: don't retry
            logger.error(f"Payment gateway error: {e}")
            raise
    except ValueError as e:
        # Schema validation error: don't retry
        logger.error(f"Payment gateway response invalid: {e}")
        raise

try:
    result = call_payment_gateway(order_id=123, amount=99.99)
except Exception as e:
    logger.error(f"Payment failed after retries: {e}")
    # Notify user, mark order as failed
    order.status = 'payment_failed'
    db.session.commit()
```

---

## Summary Scoring

Use this matrix to rate API security posture:

| API Risk | Status | Evidence | Remediation |
|---|---|---|---|
| **API1: BOLA** | ✅ Compliant | Authorization checks verified | N/A |
| **API2: Authentication** | ⚠️ Partial | JWT expires, MFA not implemented | Implement MFA for admin |
| **API3: Mass Assignment** | ❌ Non-compliant | isAdmin settable by users | Deploy whitelist validation |
| **API4: Resource Consumption** | ✅ Compliant | Rate limiting enforced | N/A |
| **API5: Function Level Auth** | ✅ Compliant | Role checks on all admin endpoints | N/A |
| **API6: Business Logic** | ⚠️ Partial | State machine implemented, race conditions possible | Add transactional locks |
| **API7: SSRF** | ✅ Compliant | URL whitelist, IP blocking enforced | N/A |
| **API8: Asset Management** | ⚠️ Partial | OpenAPI spec 90% complete | Document shadow APIs |
| **API9: Inventory** | ⚠️ Partial | API owners assigned, no change tracking | Add API approval workflow |
| **API10: Third-Party APIs** | ⚠️ Partial | Timeouts enforced, no schema validation | Add response schema validation |

**Overall Score: 70% (7/10 compliant)**
**Target: 95% within 90 days**
