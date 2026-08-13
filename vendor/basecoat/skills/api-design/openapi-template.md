# OpenAPI Specification Template

Use this template to define an API contract before implementation begins. Fill in all sections. Leave no section blank — use `N/A` if a section does not apply.

---

## API Overview

| Field | Value |
|---|---|
| **API Name** | `<service-name> API` |
| **Version** | `v1` |
| **Base Path** | `/v1/<resource>` |
| **Auth Scheme** | Bearer token / API key / OAuth 2.0 / None |
| **Owner** | `<team or service name>` |
| **Last Updated** | `YYYY-MM-DD` |

---

## OpenAPI 3.x Skeleton

```yaml
openapi: "3.0.3"
info:
  title: "<Service Name> API"
  version: "1.0.0"
  description: "<One-sentence description of what this API does.>"
  contact:
    name: "<Team Name>"
    email: "<team-email@example.com>"
  license:
    name: "MIT"
    url: "https://opensource.org/licenses/MIT"

servers:
  - url: "https://api.example.com/v1"
    description: Production
  - url: "https://api-staging.example.com/v1"
    description: Staging

security:
  - BearerAuth: []

paths:
  /<resource>:
    get:
      summary: "List <resources>"
      description: "Returns a paginated list of <resources>."
      operationId: "list<Resource>"
      tags:
        - <Resource>
      parameters:
        - name: pageSize
          in: query
          description: "Number of items per page"
          schema:
            type: integer
            default: 20
            minimum: 1
            maximum: 100
        - name: cursor
          in: query
          description: "Pagination cursor from a previous response"
          schema:
            type: string
        - name: sort
          in: query
          description: "Sort field and direction (e.g., createdAt:desc)"
          schema:
            type: string
      responses:
        "200":
          description: "Paginated list of <resources>"
          content:
            application/json:
              schema:
                $ref: "#/components/schemas/<Resource>ListResponse"
        "400":
          $ref: "#/components/responses/BadRequest"
        "401":
          $ref: "#/components/responses/Unauthorized"
        "500":
          $ref: "#/components/responses/InternalServerError"

    post:
      summary: "Create a <resource>"
      description: "Creates a new <resource> and returns the created object."
      operationId: "create<Resource>"
      tags:
        - <Resource>
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: "#/components/schemas/Create<Resource>Request"
      responses:
        "201":
          description: "<Resource> created"
          content:
            application/json:
              schema:
                $ref: "#/components/schemas/<Resource>"
        "400":
          $ref: "#/components/responses/BadRequest"
        "401":
          $ref: "#/components/responses/Unauthorized"
        "409":
          $ref: "#/components/responses/Conflict"
        "422":
          $ref: "#/components/responses/ValidationError"
        "500":
          $ref: "#/components/responses/InternalServerError"

  /<resource>/{id}:
    get:
      summary: "Get a <resource> by ID"
      description: "Returns a single <resource> by its unique identifier."
      operationId: "get<Resource>"
      tags:
        - <Resource>
      parameters:
        - name: id
          in: path
          required: true
          description: "Unique identifier of the <resource>"
          schema:
            type: string
            format: uuid
      responses:
        "200":
          description: "<Resource> found"
          content:
            application/json:
              schema:
                $ref: "#/components/schemas/<Resource>"
        "401":
          $ref: "#/components/responses/Unauthorized"
        "404":
          $ref: "#/components/responses/NotFound"
        "500":
          $ref: "#/components/responses/InternalServerError"

    patch:
      summary: "Update a <resource>"
      description: "Partially updates an existing <resource>. Only provided fields are modified."
      operationId: "update<Resource>"
      tags:
        - <Resource>
      parameters:
        - name: id
          in: path
          required: true
          description: "Unique identifier of the <resource>"
          schema:
            type: string
            format: uuid
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: "#/components/schemas/Update<Resource>Request"
      responses:
        "200":
          description: "<Resource> updated"
          content:
            application/json:
              schema:
                $ref: "#/components/schemas/<Resource>"
        "400":
          $ref: "#/components/responses/BadRequest"
        "401":
          $ref: "#/components/responses/Unauthorized"
        "404":
          $ref: "#/components/responses/NotFound"
        "409":
          $ref: "#/components/responses/Conflict"
        "422":
          $ref: "#/components/responses/ValidationError"
        "500":
          $ref: "#/components/responses/InternalServerError"

    delete:
      summary: "Delete a <resource>"
      description: "Permanently deletes a <resource>. This action cannot be undone."
      operationId: "delete<Resource>"
      tags:
        - <Resource>
      parameters:
        - name: id
          in: path
          required: true
          description: "Unique identifier of the <resource>"
          schema:
            type: string
            format: uuid
      responses:
        "204":
          description: "<Resource> deleted"
        "401":
          $ref: "#/components/responses/Unauthorized"
        "404":
          $ref: "#/components/responses/NotFound"
        "500":
          $ref: "#/components/responses/InternalServerError"

components:
  securitySchemes:
    BearerAuth:
      type: http
      scheme: bearer
      bearerFormat: JWT

  schemas:
    <Resource>:
      type: object
      required:
        - id
        - createdAt
        - updatedAt
      properties:
        id:
          type: string
          format: uuid
          description: "Unique identifier"
        createdAt:
          type: string
          format: date-time
          description: "Timestamp when the resource was created"
        updatedAt:
          type: string
          format: date-time
          description: "Timestamp when the resource was last updated"
        # Add domain-specific properties here

    Create<Resource>Request:
      type: object
      required:
        - # list required fields
      properties:
        # Add create-request properties here

    Update<Resource>Request:
      type: object
      properties:
        # Add update-request properties here (all optional for PATCH)

    <Resource>ListResponse:
      type: object
      required:
        - data
        - pagination
      properties:
        data:
          type: array
          items:
            $ref: "#/components/schemas/<Resource>"
        pagination:
          $ref: "#/components/schemas/PaginationMeta"

    PaginationMeta:
      type: object
      required:
        - total
        - pageSize
      properties:
        total:
          type: integer
          description: "Total number of items matching the query"
        pageSize:
          type: integer
          description: "Number of items per page"
        nextCursor:
          type: string
          nullable: true
          description: "Cursor to retrieve the next page, null if no more pages"

    ErrorEnvelope:
      type: object
      required:
        - error
      properties:
        error:
          type: object
          required:
            - code
            - message
            - correlationId
          properties:
            code:
              type: string
              description: "Machine-readable error code from the error catalog"
              example: "VALIDATION_FAILED"
            message:
              type: string
              description: "Human-readable error message safe to display"
            details:
              type: array
              description: "Field-level validation errors (present on VALIDATION_FAILED)"
              items:
                type: object
                properties:
                  field:
                    type: string
                  issue:
                    type: string
            correlationId:
              type: string
              format: uuid
              description: "Unique ID for tracing this request across services"

  responses:
    BadRequest:
      description: "Bad request — malformed input"
      content:
        application/json:
          schema:
            $ref: "#/components/schemas/ErrorEnvelope"
    Unauthorized:
      description: "Unauthenticated — missing or invalid credentials"
      content:
        application/json:
          schema:
            $ref: "#/components/schemas/ErrorEnvelope"
    NotFound:
      description: "Resource not found"
      content:
        application/json:
          schema:
            $ref: "#/components/schemas/ErrorEnvelope"
    Conflict:
      description: "Conflict — resource already exists or concurrent modification"
      content:
        application/json:
          schema:
            $ref: "#/components/schemas/ErrorEnvelope"
    ValidationError:
      description: "Unprocessable entity — validation failure"
      content:
        application/json:
          schema:
            $ref: "#/components/schemas/ErrorEnvelope"
    InternalServerError:
      description: "Internal server error"
      content:
        application/json:
          schema:
            $ref: "#/components/schemas/ErrorEnvelope"
```

---

## Endpoint Summary

| Method | Path | Auth | Description |
|---|---|---|---|
| `GET` | `/v1/<resource>` | Required | List with pagination, sorting, and filtering |
| `POST` | `/v1/<resource>` | Required | Create a new resource |
| `GET` | `/v1/<resource>/{id}` | Required | Get a single resource by ID |
| `PATCH` | `/v1/<resource>/{id}` | Required | Partially update a resource |
| `DELETE` | `/v1/<resource>/{id}` | Required | Delete a resource |

## Customization Notes

- Replace `<resource>` and `<Resource>` with your actual resource name (e.g., `orders` / `Order`).
- Add domain-specific properties to each schema.
- Add domain-specific error codes to the error catalog.
- Add additional endpoints (batch operations, sub-resources, actions) as needed.
- If using GraphQL instead of REST, use this template as a reference for field naming and error handling conventions, then author SDL directly.
