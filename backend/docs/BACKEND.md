# Backend Architecture & API Reference

## Philosophy

The backend is a Go REST API built with Echo v5. It follows **strict clean-architecture layering with zero reflection and zero dependency injection framework** — every dependency is wired manually in `cmd/api/main.go`. This makes the data flow completely traceable: every request path can be followed from the route handler to the SQL query without jumping through container registrations.

---

## Layered Architecture

```
HTTP Request
     │
     ▼
Controller  (internal/controller/http/v1/)
  │   Parses HTTP, validates input, calls use case, formats response.
  │   Declares a local interface for the use case it needs.
  │
  ▼
Use Case    (internal/usecase/<feature>/usecase.go)
  │   Pure business logic. Orchestrates repositories.
  │   Declares a local interface for each repository it needs.
  │   No imports from the controller or other use cases.
  │
  ▼
Repository  (internal/repo/persistent/)
  │   SQL queries only. Uses pgx v5 directly (no ORM).
  │   Implements the interface declared by the use case above it.
  │
  ▼
PostgreSQL 16
```

**Key rule:** dependencies only flow inward. A use case never imports a controller type. A repository never imports a use case type. Each layer defines the interface it needs from the layer below it — the concrete type lives in the outer layer and is injected at startup.

### Layer Paths

| Layer | Path | Notes |
|---|---|---|
| Controller | `internal/controller/http/v1/` | Echo handlers, request binding, response formatting |
| Use Case | `internal/usecase/<feature>/usecase.go` | Business rules, no HTTP knowledge |
| Repository | `internal/repo/persistent/` | pgx v5 queries, interface in `common_contracts.go` |
| Entity | `internal/entity/` | Domain structs, enums, sentinel errors |
| DTO | `internal/dto/` | `httprequest/` for input, `httpresponse/` for output |
| Config | `internal/cfg/config.go` | All config from env vars via `caarlos0/env` |

---

## Adding a New Feature

Follow this exact pattern — it's enforced by the architecture:

1. **Entity** — add struct/enum/sentinel error to `internal/entity/`
2. **Repository** — add interface to `internal/repo/common_contracts.go`, implement in `internal/repo/persistent/<feature>_postgres.go`
3. **Use Case** — create `internal/usecase/<feature>/usecase.go`, declare a local repo interface at the top of the file
4. **Controller** — create `internal/controller/http/v1/<feature>.go`, declare a local usecase interface at the top
5. **Router** — add field + constructor param to `internal/controller/http/router.go`, register routes in `RegisterRoutes()`
6. **Wire** — instantiate repo → use case → controller in `cmd/api/main.go`, pass to router

---

## Configuration

All config is loaded from environment variables. No config files — everything is in the environment, making Docker and EC2 deployment straightforward.

| Variable | Default | Description |
|---|---|---|
| `HTTP_SERVER_PORT` | `:8080` | Listen address |
| `ENVIRONMENT` | `development` | Affects log format |
| `JWT_SECRET` | — | **Required.** HMAC signing key for JWT |
| `JWT_DURATION` | `6h` | Token TTL |
| `POSTGRES_CONNECTION_URI` | — | **Required.** Full DSN |
| `POSTGRES_MAX_CONNS` | `25` | pgx pool max |
| `POSTGRES_MIN_CONNS` | `5` | pgx pool min |
| `PREDICTION_INTERVAL` | `1h` | AI background loop interval |
| `GROQ_API_KEY` | _(empty)_ | Optional. Leave blank to disable LLM rationale |
| `GROQ_MODEL` | `llama-3.1-8b-instant` | Groq model ID |
| `LOG_LEVEL` | `info` | `debug` / `info` / `warn` / `error` |

---

## Running

### Docker Compose (recommended)

```bash
cd backend
cp .env.example .env   # set JWT_SECRET at minimum
docker compose up -d   # starts postgres, runs migrations, starts API
```

### Local (with race detector)

```bash
cd backend
make start-deps   # docker compose up postgres
make migrate-up   # run all pending migrations
make start        # go run -race ./cmd/api
```

### Regenerate Swagger

```bash
cd backend && make gen-swag
```

---

## Request Flow

Every request is logged by the `RequestLogger` middleware:

```
→ RequestLogger middleware wraps response writer to capture status code
→ JWT middleware validates token, injects UserClaims into context
→ Pagination middleware injects limit/offset into context
→ Controller handler: bind → validate → call use case → format response
→ RequestLogger logs: method, path, status, latency_ms, ip
```

Validation uses the Echo validator (`go-playground/validator`). Binding supports both JSON body and query params.

---

## Error Handling

Sentinel errors live in `internal/entity/error.go`:

```go
var (
    ErrNotFound   = errors.New("not found")
    ErrForbidden  = errors.New("forbidden")
    ErrBadRequest = errors.New("bad request")
    ErrConflict   = errors.New("conflict")
)
```

They map to HTTP status codes in `internal/dto/httpresponse/error_mapping.go`. Controllers always call:

```go
return httpresponse.NewErrorResponse(ctx, err)
// or with a hint:
return httpresponse.NewErrorResponse(ctx, entity.ErrBadRequest, "invalid request id")
```

The mapping is automatic — no switch statements in handlers.

---

## Authentication

JWT tokens are issued on `POST /v1/auth/login`. The payload carries `user_id`, `username`, and `role`. All protected routes require `Authorization: Bearer <token>`.

The JWT middleware runs per-group, not globally. Public routes (`/v1/auth/login`, `/health`) are outside the protected group.

Role enforcement is done **inside use cases and controllers**, not in middleware. This keeps the enforcement logic close to the business rule it protects and makes it easy to test.

```go
actor := ctx.Get(entity.UserKey).(dto.UserClaims)
if actor.Role == entity.UserRoleWorker {
    return httpresponse.NewErrorResponse(ctx, entity.ErrForbidden)
}
```

---

## Database

PostgreSQL 16, accessed via `pgx/v5` directly. No ORM. Migrations are managed by `golang-migrate`.

```bash
make migrate-up     # apply all pending migrations
make migrate-down   # roll back one step
```

Migration files live in `backend/migrations/dev/`, named `{timestamp}_{description}.{up|down}.sql`.

### Key Tables

| Table | Purpose |
|---|---|
| `warehouses` | 20 warehouse locations with lat/lon |
| `customers` | 40 delivery points (shops + malls) |
| `users` | User accounts with role and warehouse assignment |
| `resources` | 30 resource types with category and unit |
| `inventories` | Stock per (warehouse, resource) pair |
| `delivery_requests` | End-to-end delivery lifecycle |
| `delivery_request_items` | Line items per request |
| `allocations` | Per-source-warehouse fulfillment units |
| `demand_readings` | Time-series demand data per (point, resource) |
| `predictive_alerts` | AI-generated shortage warnings |
| `rebalancing_proposals` | Optimal transfer plans linked to alerts |
| `rebalancing_transfers` | Individual warehouse→point transfers in a proposal |
| `audit_log` | Append-only action history |

---

## API Reference

All routes are under `/v1`. Protected routes require `Authorization: Bearer <token>`.

### Auth

| Method | Path | Auth | Description |
|---|---|---|---|
| `POST` | `/v1/auth/login` | No | Login, returns JWT |
| `GET` | `/v1/auth/me` | Yes | Current user profile |
| `POST` | `/v1/auth/create` | Admin | Create a new user account |

**Login:**
```json
POST /v1/auth/login
{ "username": "dispatcher_w1", "password": "secret" }
→ { "data": "<jwt>", "status": 200 }
```

---

### Inventory

| Method | Path | Auth | Description |
|---|---|---|---|
| `GET` | `/v1/inventory/:location_id` | Yes | Paginated inventory for a warehouse or customer |

Query params: `page`, `pageSize`, `resource_name` (partial match), `resource_category`.

Workers only see their own `location_id`. Dispatchers and admins can query any location.

---

### Delivery Requests

| Method | Path | Auth | Description |
|---|---|---|---|
| `POST` | `/v1/delivery-requests` | Worker+ | Create a delivery request |
| `GET` | `/v1/delivery-requests` | Yes | List (workers see only their own) |
| `GET` | `/v1/delivery-requests/:id` | Yes | Single request with items and allocations |
| `POST` | `/v1/delivery-requests/allocate` | Dispatcher+ | Auto-allocate all pending requests |
| `POST` | `/v1/delivery-requests/:id/cancel` | Yes | Cancel a pending request |
| `POST` | `/v1/delivery-requests/:id/deliver` | Dispatcher+ | Mark as delivered |
| `POST` | `/v1/delivery-requests/:id/escalate` | Yes | Escalate priority one level |
| `PATCH` | `/v1/delivery-requests/:id/items` | Yes | Update item quantity (pending only) |
| `POST` | `/v1/delivery-requests/:id/approve-all` | Dispatcher+ | Approve all planned allocations |

**Status machine:**
```
pending → allocated → in_transit → delivered
                  ↘ cancelled
```

**Priority levels:** `normal` → `elevated` → `critical` → `urgent`

Urgent requests auto-allocate on creation (skip the manual allocate step).

---

### Allocations

| Method | Path | Auth | Description |
|---|---|---|---|
| `GET` | `/v1/allocations` | Yes | List allocations |
| `POST` | `/v1/allocations/:id/approve` | Dispatcher+ | Approve a planned allocation |
| `POST` | `/v1/allocations/:id/reject` | Dispatcher+ | Reject with a reason string |
| `POST` | `/v1/allocations/:id/dispatch` | Yes | Mark as dispatched (in transit) |

**Allocation status machine:**
```
planned → approved → in_transit → delivered
       ↘ cancelled
```

---

### Stock

| Method | Path | Auth | Description |
|---|---|---|---|
| `GET` | `/v1/stock/nearest` | Yes | Nearest warehouses with surplus for a resource |

Query params: `resource_id`, `point_id`, `quantity` (optional). Returns candidates ranked by `(surplus × 0.6) − (distance × 0.4)`.

---

### Map

| Method | Path | Auth | Description |
|---|---|---|---|
| `GET` | `/v1/map/points` | Yes | All warehouses and customers with current status |

```json
{ "id": 3, "name": "Ocean Plaza Київ", "type": "customer",
  "lat": 50.4167, "lng": 30.5167, "status": "critical", "alert_count": 2 }
```

---

### AI / Prediction

| Method | Path | Auth | Description |
|---|---|---|---|
| `POST` | `/v1/demand-readings` | Yes | Record a demand reading |
| `GET` | `/v1/demand-readings/:point_id` | Yes | Demand history for a delivery point |
| `GET` | `/v1/predictive-alerts` | Yes | Open alerts sorted by confidence (desc) |
| `GET` | `/v1/predictive-alerts/:point_id` | Yes | Alerts for a specific point |
| `POST` | `/v1/predictive-alerts/:alert_id/dismiss` | Yes | Dismiss an alert |
| `GET` | `/v1/rebalancing-proposals/:proposal_id` | Yes | Proposal with transfer list |
| `POST` | `/v1/rebalancing-proposals/:proposal_id/approve` | Yes | Approve — resolves linked alert |
| `POST` | `/v1/rebalancing-proposals/:proposal_id/dismiss` | Yes | Dismiss a proposal |
| `POST` | `/v1/ai/run` | Yes | Manually trigger prediction run |

`POST /v1/ai/run` returns `202 Accepted` immediately. The prediction runs in a background goroutine. Approving a proposal automatically resolves the linked alert (it disappears from the open queue).

---

### Audit Log

| Method | Path | Auth | Description |
|---|---|---|---|
| `GET` | `/v1/audit-log` | Admin | Paginated audit trail |

Query params: `page`, `pageSize`, `actor_id`, `action`, `entity_type`.

---

### Health

| Method | Path | Auth | Description |
|---|---|---|---|
| `GET` | `/health` | No | Liveness check |

```json
{ "status": "healthy" }
```

---

## Swagger

Auto-generated Swagger UI is served at `/swagger/index.html` on the running server. To regenerate after modifying godoc annotations:

```bash
cd backend && make gen-swag
```

---

## Logging

Structured `slog` logging at every layer. Each controller prefixes logs with `"controller", "<name>"` and each method with `"method", "<name>"`. The `RequestLogger` middleware adds per-request log lines with method, path, status, latency, and client IP.

```
2026-04-05 12:00:01 INFO request method=POST path=/v1/ai/run status=202 latency_ms=3 ip=1.2.3.4
2026-04-05 12:00:01 INFO prediction run triggered manually
```
