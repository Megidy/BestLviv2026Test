# Backend Architecture & API Reference

## Overview

The backend is a Go REST API built with Echo v5. It follows a strict clean-architecture layering with no dependency injection framework — all wiring is done manually in `cmd/api/main.go`.

## Layered Architecture

```
Controller (HTTP) → Use Case → Repository → PostgreSQL
```

Dependencies flow strictly inward. Each layer defines a local interface for the layer below it — no layer imports a concrete type from another.

| Layer | Path | Role |
|---|---|---|
| Controller | `internal/controller/http/v1/` | Parse HTTP, validate, call use case, format response |
| Use Case | `internal/usecase/<feature>/` | Business rules, orchestration |
| Repository | `internal/repo/persistent/` | SQL queries via pgx v5 |
| Entity | `internal/entity/` | Domain structs, enums, sentinel errors |
| DTO | `internal/dto/` | Request/response shapes (separate from entities) |

## Configuration

All config is loaded from environment variables via `caarlos0/env`. See `backend/.env.example` for the full list.

| Variable | Default | Description |
|---|---|---|
| `HTTP_SERVER_PORT` | `:8080` | Listen address |
| `JWT_SECRET` | — | Required. Sign key for JWT tokens |
| `JWT_DURATION` | `6h` | Token TTL |
| `POSTGRES_CONNECTION_URI` | — | Full DSN |
| `PREDICTION_INTERVAL` | `1h` | How often the AI loop runs |
| `GROQ_API_KEY` | _(empty)_ | Optional. Leave blank to disable LLM rationale |
| `GROQ_MODEL` | `llama-3.1-8b-instant` | Groq model name |

## Running Locally

```bash
# Start Postgres + run migrations + start server
cd backend
make start-deps    # docker compose up postgres
make migrate-up    # run all pending migrations
make start         # go run with -race
```

Or fully containerized:

```bash
docker compose up -d   # starts postgres, migrate, backend
```

## Adding a New Feature

Follow this pattern exactly:

1. **Entity** — add struct/enum/error to `internal/entity/`
2. **Repository** — add interface + `*Repo` struct to `internal/repo/persistent/`
3. **Use Case** — create `internal/usecase/<feature>/usecase.go`, declare a local repo interface
4. **Controller** — create `internal/controller/http/v1/<feature>.go`, declare a local usecase interface
5. **Router** — add field + constructor param to `internal/controller/http/router.go`, register routes
6. **Wire** — instantiate everything in `cmd/api/main.go`

## Error Handling

Sentinel errors live in `internal/entity/error.go`. They map to HTTP status codes in `internal/dto/httpresponse/error_mapping.go`. Controllers call `httpresponse.NewErrorResponse(ctx, err)` — the mapping is automatic.

## Authentication

JWT middleware is applied per-route group. The token carries `user_id` and `role`. Controllers read claims via:

```go
claims := ctx.Get(entity.UserKey).(dto.UserClaims)
```

Role enforcement is done inside the use case or controller — not in middleware.

---

## API Reference

All routes are under `/v1`. All protected routes require `Authorization: Bearer <token>`.

### Auth

| Method | Path | Auth | Description |
|---|---|---|---|
| POST | `/v1/auth/login` | No | Login, returns JWT |
| GET | `/v1/auth/me` | Yes | Get current user profile |
| POST | `/v1/auth/create` | Admin | Create a new user |

**Login request:**
```json
{ "username": "admin_w1", "password": "secret" }
```

**Login response:**
```json
{ "data": "<jwt_token>", "status": 200 }
```

---

### Inventory

| Method | Path | Auth | Description |
|---|---|---|---|
| GET | `/v1/inventory/:location_id` | Yes | Paginated inventory for a warehouse or customer location |

Query params: `page`, `pageSize`, `resource_name` (partial match), `resource_category`.

---

### Delivery Requests

| Method | Path | Auth | Description |
|---|---|---|---|
| POST | `/v1/delivery-requests` | Worker | Create a multi-item delivery request |
| GET | `/v1/delivery-requests` | Yes | List requests (filterable, paginated) |
| GET | `/v1/delivery-requests/:id` | Yes | Get single request with items and allocations |
| POST | `/v1/delivery-requests/:id/cancel` | Yes | Cancel a pending request |
| POST | `/v1/delivery-requests/:id/deliver` | Dispatcher | Mark as delivered |
| POST | `/v1/delivery-requests/:id/escalate` | Yes | Escalate priority |
| PATCH | `/v1/delivery-requests/:id/items` | Yes | Update item quantity |
| POST | `/v1/delivery-requests/allocate` | Dispatcher | Auto-allocate all pending requests |
| POST | `/v1/delivery-requests/:id/approve-all` | Yes | Approve all allocations for a request |

### Allocations

| Method | Path | Auth | Description |
|---|---|---|---|
| GET | `/v1/allocations` | Yes | List allocations (filterable, paginated) |
| POST | `/v1/allocations/:id/approve` | Dispatcher | Approve an allocation |
| POST | `/v1/allocations/:id/reject` | Dispatcher | Reject with reason |
| POST | `/v1/allocations/:id/dispatch` | Dispatcher | Mark dispatched |

### Stock

| Method | Path | Auth | Description |
|---|---|---|---|
| GET | `/v1/stock/nearest` | Yes | Find nearest warehouse with stock for a resource |

### Audit Log

| Method | Path | Auth | Description |
|---|---|---|---|
| GET | `/v1/audit-log` | Yes | Paginated audit trail of all delivery actions |

---

### Map

| Method | Path | Auth | Description |
|---|---|---|---|
| GET | `/v1/map/points` | Yes | All warehouses and customers with status |

Response shape per point:
```json
{
  "id": 1,
  "name": "Склад Київ-Центральний",
  "type": "warehouse",
  "lat": 50.4501,
  "lng": 30.5234,
  "status": "normal",
  "alert_count": 0
}
```

Status values: `normal` · `elevated` · `critical`

---

### AI / Prediction

| Method | Path | Auth | Description |
|---|---|---|---|
| POST | `/v1/demand-readings` | Yes | Record a demand reading for a point+resource pair |
| GET | `/v1/demand-readings/:point_id` | Yes | Get demand history for a delivery point |
| GET | `/v1/predictive-alerts` | Yes | List open predictive alerts (sorted by confidence) |
| GET | `/v1/predictive-alerts/:point_id` | Yes | All alerts for a specific delivery point |
| POST | `/v1/predictive-alerts/:alert_id/dismiss` | Yes | Dismiss an alert |
| GET | `/v1/rebalancing-proposals/:proposal_id` | Yes | Get a proposal with its transfer list |
| POST | `/v1/rebalancing-proposals/:proposal_id/approve` | Yes | Approve a rebalancing proposal |
| POST | `/v1/rebalancing-proposals/:proposal_id/dismiss` | Yes | Dismiss a proposal |
| POST | `/v1/ai/run` | Yes | Manually trigger the prediction run (no wait for interval) |

### Health

| Method | Path | Auth | Description |
|---|---|---|---|
| GET | `/health` | No | Liveness check — returns `{"status":"healthy"}` |

---

## Swagger

Auto-generated Swagger UI is served at `/swagger/index.html`.

To regenerate after adding godoc annotations:

```bash
cd backend && make gen-swag
```
